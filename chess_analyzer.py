#!/usr/bin/env python3
"""
Chess Board Analyzer
====================
Nimmt den Bildschirm auf, erkennt das Schachbrett, analysiert die Stellung
mit Stockfish und zeigt den besten Zug an.

Bedienung:
  - Programm starten
  - Brett-Bereich mit der Maus auswählen (Klick + Drag)
  - Danach wird automatisch alle 2 Sekunden analysiert
  - 'r' = Brett neu auswählen
  - 'f' = Seite wechseln (Weiß/Schwarz unten)
  - 'q' = Beenden
"""

import sys
import time
import subprocess
import threading
import queue
import chess
import chess.engine
import mss
import numpy as np
import cv2
from PIL import Image

STOCKFISH_PATH = "/usr/games/stockfish"
ANALYSIS_TIME = 1.5      # Sekunden pro Analyse
REFRESH_INTERVAL = 2.0   # Sekunden zwischen Aufnahmen

# Figurenfarben (HSV-Bereiche) — passen für die meisten Online-Schachseiten
PIECE_TEMPLATES = {}  # wird per Template Matching nicht genutzt; stattdessen Helligkeitsanalyse

# Schachfigurenzeichen für Terminal-Ausgabe
PIECE_SYMBOLS = {
    chess.PAWN:   ("♟", "♙"),
    chess.KNIGHT: ("♞", "♘"),
    chess.BISHOP: ("♝", "♗"),
    chess.ROOK:   ("♜", "♖"),
    chess.QUEEN:  ("♛", "♕"),
    chess.KING:   ("♚", "♔"),
}

# ──────────────────────────────────────────────
# Bildschirmauswahl
# ──────────────────────────────────────────────

selected_region = None
selecting = False
start_x = start_y = 0

def select_region():
    """Öffnet ein transparentes Fenster zum Auswählen des Brett-Bereichs."""
    global selected_region, selecting, start_x, start_y

    with mss.mss() as sct:
        monitor = sct.monitors[0]
        screen_w = monitor["width"]
        screen_h = monitor["height"]
        img = np.array(sct.grab(monitor))

    canvas = img[:, :, :3].copy()
    overlay = canvas.copy()
    clone = canvas.copy()

    drawing = [False]
    rect = [0, 0, 0, 0]

    def mouse_cb(event, x, y, flags, _):
        if event == cv2.EVENT_LBUTTONDOWN:
            drawing[0] = True
            rect[0], rect[1] = x, y
            rect[2], rect[3] = x, y
        elif event == cv2.EVENT_MOUSEMOVE and drawing[0]:
            rect[2], rect[3] = x, y
            temp = clone.copy()
            cv2.rectangle(temp, (rect[0], rect[1]), (rect[2], rect[3]), (0, 255, 0), 2)
            cv2.imshow("Brett auswaehlen — Ziehe ein Rechteck, dann ENTER", temp)
        elif event == cv2.EVENT_LBUTTONUP:
            drawing[0] = False
            rect[2], rect[3] = x, y

    win_name = "Brett auswaehlen — Ziehe ein Rechteck, dann ENTER"
    cv2.namedWindow(win_name, cv2.WINDOW_NORMAL)
    cv2.setWindowProperty(win_name, cv2.WND_PROP_FULLSCREEN, cv2.WINDOW_FULLSCREEN)
    cv2.imshow(win_name, canvas)
    cv2.setMouseCallback(win_name, mouse_cb)

    while True:
        key = cv2.waitKey(50) & 0xFF
        if key == 13 or key == ord('\n'):  # Enter
            break
        if key == ord('q'):
            cv2.destroyAllWindows()
            sys.exit(0)

    cv2.destroyAllWindows()

    x1, y1 = min(rect[0], rect[2]), min(rect[1], rect[3])
    x2, y2 = max(rect[0], rect[2]), max(rect[1], rect[3])
    if x2 - x1 < 50 or y2 - y1 < 50:
        print("Zu kleiner Bereich — nochmal versuchen.")
        return select_region()

    selected_region = {"top": y1, "left": x1, "width": x2 - x1, "height": y2 - y1}
    return selected_region


# ──────────────────────────────────────────────
# Board-Erkennung
# ──────────────────────────────────────────────

def capture_board(region):
    """Screenshot des gewählten Bereichs."""
    with mss.mss() as sct:
        raw = sct.grab(region)
    img = Image.frombytes("RGB", raw.size, raw.bgra, "raw", "BGRX")
    return np.array(img)


def extract_squares(board_img):
    """Schneidet das Brettbild in 64 Felder (8×8)."""
    h, w = board_img.shape[:2]
    sq_h = h // 8
    sq_w = w // 8
    squares = []
    for row in range(8):
        for col in range(8):
            y1 = row * sq_h
            y2 = (row + 1) * sq_h
            x1 = col * sq_w
            x2 = (col + 1) * sq_w
            squares.append(board_img[y1:y2, x1:x2])
    return squares


def classify_square(sq_img, is_light_square):
    """
    Erkennt Figur + Farbe auf einem Feld.
    Nutzt Sättigungs- und Helligkeitsanalyse im HSV-Raum.
    Gibt (chess.Piece oder None) zurück.
    """
    hsv = cv2.cvtColor(sq_img, cv2.COLOR_RGB2HSV)
    h_ch, s_ch, v_ch = hsv[:, :, 0], hsv[:, :, 1], hsv[:, :, 2]

    # Randbereich abschneiden (Rahmen ignorieren)
    margin = sq_img.shape[0] // 6
    center_v = v_ch[margin:-margin, margin:-margin]
    center_s = s_ch[margin:-margin, margin:-margin]

    mean_v = float(np.mean(center_v))
    mean_s = float(np.mean(center_s))

    # Hintergrundfarbe des Feldes
    bg_v = 200.0 if is_light_square else 100.0

    # Abweichung vom Hintergrund → Figur vorhanden?
    deviation = abs(mean_v - bg_v)

    if deviation < 18 and mean_s < 30:
        return None  # Leeres Feld

    # Farbe der Figur: helle Figur = Weiß, dunkle Figur = Schwarz
    # Relativ zum Feldtyp beurteilen
    if is_light_square:
        piece_color = chess.WHITE if mean_v > bg_v - 10 else chess.BLACK
    else:
        piece_color = chess.WHITE if mean_v > bg_v + 20 else chess.BLACK

    # Figurentyp: Shape-basiert über Kantendichte
    edges = cv2.Canny(cv2.cvtColor(sq_img, cv2.COLOR_RGB2GRAY), 30, 100)
    edge_density = float(np.sum(edges > 0)) / edges.size

    # Grobe Heuristik nach Kantendichte
    if edge_density < 0.04:
        piece_type = chess.PAWN
    elif edge_density < 0.07:
        piece_type = chess.BISHOP
    elif edge_density < 0.10:
        piece_type = chess.ROOK
    elif edge_density < 0.13:
        piece_type = chess.KNIGHT
    elif edge_density < 0.17:
        piece_type = chess.QUEEN
    else:
        piece_type = chess.KING

    return chess.Piece(piece_type, piece_color)


def image_to_board(board_img, white_bottom=True):
    """
    Konvertiert das Brettbild in ein chess.Board.
    white_bottom=True → Weiß spielt von unten (Standard).
    """
    squares = extract_squares(board_img)
    board = chess.Board(fen=None)  # leeres Brett
    board.clear()

    for idx, sq_img in enumerate(squares):
        row = idx // 8
        col = idx % 8

        # Helles / dunkles Feld bestimmen
        is_light = (row + col) % 2 == 0

        piece = classify_square(sq_img, is_light)
        if piece is None:
            continue

        # Koordinaten → chess-Feld
        if white_bottom:
            file_ = col          # a=0 … h=7
            rank_ = 7 - row      # 8=0 … 1=7
        else:
            file_ = 7 - col
            rank_ = row

        square = chess.square(file_, rank_)
        board.set_piece_at(square, piece)

    # Aktiven Spieler setzen (wir wissen es nicht sicher → Weiß als Standard)
    board.turn = chess.WHITE
    return board


# ──────────────────────────────────────────────
# Stockfish-Analyse
# ──────────────────────────────────────────────

def analyze_position(board, engine, time_limit=ANALYSIS_TIME):
    """Gibt (beste Zugnation, Bewertung) zurück."""
    try:
        result = engine.analyse(board, chess.engine.Limit(time=time_limit))
        best_move = result.get("pv", [None])[0]
        score = result.get("score")
        return best_move, score
    except Exception as e:
        return None, None


def format_score(score, turn):
    """Formatiert die Stockfish-Bewertung menschenlesbar."""
    if score is None:
        return "?"
    pov = score.pov(turn)
    if pov.is_mate():
        m = pov.mate()
        return f"Matt in {abs(m)}" if m > 0 else f"Gegner Matt in {abs(m)}"
    cp = pov.score()
    if cp is None:
        return "?"
    sign = "+" if cp >= 0 else ""
    return f"{sign}{cp / 100:.2f}"


# ──────────────────────────────────────────────
# Anzeige
# ──────────────────────────────────────────────

def draw_move_on_image(board_img, best_move, board, white_bottom=True):
    """Zeichnet den besten Zug als Pfeil auf das Brettbild."""
    if best_move is None:
        return board_img

    img = board_img.copy()
    h, w = img.shape[:2]
    sq_h = h // 8
    sq_w = w // 8

    def sq_to_pixel(sq):
        file_ = chess.square_file(sq)
        rank_ = chess.square_rank(sq)
        if white_bottom:
            col = file_
            row = 7 - rank_
        else:
            col = 7 - file_
            row = rank_
        cx = int((col + 0.5) * sq_w)
        cy = int((row + 0.5) * sq_h)
        return (cx, cy)

    from_sq = best_move.from_square
    to_sq = best_move.to_square

    p1 = sq_to_pixel(from_sq)
    p2 = sq_to_pixel(to_sq)

    # Highlight Startfeld
    col_f = chess.square_file(from_sq)
    rank_f = chess.square_rank(from_sq)
    if white_bottom:
        r, c = 7 - rank_f, col_f
    else:
        r, c = rank_f, 7 - col_f
    overlay = img.copy()
    cv2.rectangle(overlay,
                  (c * sq_w, r * sq_h),
                  ((c + 1) * sq_w, (r + 1) * sq_h),
                  (50, 255, 50), -1)
    img = cv2.addWeighted(overlay, 0.35, img, 0.65, 0)

    # Pfeil
    cv2.arrowedLine(img, p1, p2, (0, 220, 0), max(3, sq_w // 8),
                    tipLength=0.3, line_type=cv2.LINE_AA)
    cv2.circle(img, p1, max(6, sq_w // 6), (0, 200, 0), -1)

    return img


def render_display(board_img, board, best_move, score_str, white_bottom, fps_str=""):
    """Rendert das Hauptfenster mit Brett + Infobereich."""
    h, w = board_img.shape[:2]

    annotated = draw_move_on_image(board_img, best_move, board, white_bottom)
    bgr = cv2.cvtColor(annotated, cv2.COLOR_RGB2BGR)

    # Info-Panel rechts
    panel_w = 280
    panel = np.zeros((h, panel_w, 3), dtype=np.uint8)
    panel[:] = (25, 25, 35)

    def put(text, y, color=(220, 220, 220), scale=0.6, thick=1):
        cv2.putText(panel, text, (12, y), cv2.FONT_HERSHEY_SIMPLEX,
                    scale, color, thick, cv2.LINE_AA)

    put("CHESS ANALYZER", 35, (80, 200, 80), 0.65, 2)
    put(f"Bewertung: {score_str}", 80, (200, 200, 80))

    move_str = best_move.uci() if best_move else "---"
    put(f"Bester Zug: {move_str}", 115, (80, 180, 255), 0.75, 2)

    if best_move and board.piece_at(best_move.from_square):
        piece = board.piece_at(best_move.from_square)
        sym_b, sym_w = PIECE_SYMBOLS.get(piece.piece_type, ("?", "?"))
        sym = sym_b if piece.color == chess.BLACK else sym_w
        put(f"  Figur: {sym} {chess.piece_name(piece.piece_type)}", 150)

    seite = "Weiss unten" if white_bottom else "Schwarz unten"
    put(f"Seite: {seite}", 200, (160, 160, 160), 0.5)
    put(fps_str, 230, (120, 120, 120), 0.45)
    put("r=neu auswaehlen", 270, (120, 120, 120), 0.45)
    put("f=Seite wechseln", 295, (120, 120, 120), 0.45)
    put("q=Beenden", 320, (120, 120, 120), 0.45)

    # Brett-FEN
    fen_short = board.board_fen()
    for i, chunk in enumerate([fen_short[j:j+28] for j in range(0, len(fen_short), 28)]):
        put(chunk, 370 + i * 20, (100, 140, 100), 0.38)

    combined = np.hstack([bgr, panel])
    return combined


# ──────────────────────────────────────────────
# Haupt-Loop
# ──────────────────────────────────────────────

def main():
    print("Chess Analyzer startet...")
    print("Bitte den Schachbrett-Bereich auf dem Bildschirm auswählen.")

    region = select_region()
    print(f"Region: {region}")

    try:
        engine = chess.engine.SimpleEngine.popen_uci(STOCKFISH_PATH)
        engine.configure({"Threads": 2, "Hash": 64})
    except Exception as e:
        print(f"Stockfish konnte nicht gestartet werden: {e}")
        print(f"Pfad: {STOCKFISH_PATH}")
        sys.exit(1)

    white_bottom = True
    last_best_move = None
    last_score_str = "?"
    last_board = chess.Board()

    analysis_queue = queue.Queue(maxsize=1)
    result_queue = queue.Queue(maxsize=1)

    def analysis_worker():
        while True:
            item = analysis_queue.get()
            if item is None:
                break
            board_img, wb = item
            board = image_to_board(board_img, wb)
            move, score = analyze_position(board, engine)
            score_str = format_score(score, board.turn)
            # Alte Ergebnisse verwerfen
            try:
                result_queue.get_nowait()
            except queue.Empty:
                pass
            result_queue.put((board, move, score_str))

    worker = threading.Thread(target=analysis_worker, daemon=True)
    worker.start()

    win_name = "Chess Analyzer"
    cv2.namedWindow(win_name, cv2.WINDOW_NORMAL)

    last_capture = 0.0
    last_fps_time = time.time()
    frame_count = 0
    fps_str = ""

    print("Analyse läuft. Drücke 'q' zum Beenden, 'r' zum Neuauswählen, 'f' zum Seitenwechsel.")

    try:
        while True:
            now = time.time()

            # Periodisch neuen Screenshot in die Analyse schicken
            if now - last_capture >= REFRESH_INTERVAL:
                last_capture = now
                board_img = capture_board(region)
                try:
                    analysis_queue.put_nowait((board_img.copy(), white_bottom))
                except queue.Full:
                    pass

            # Analyseergebnis abholen (nicht blockierend)
            try:
                last_board, last_best_move, last_score_str = result_queue.get_nowait()
            except queue.Empty:
                pass

            # Aktuelles Bild holen (frisch für Anzeige)
            display_img = capture_board(region)
            frame = render_display(display_img, last_board, last_best_move,
                                   last_score_str, white_bottom, fps_str)

            cv2.imshow(win_name, frame)

            frame_count += 1
            if now - last_fps_time >= 1.0:
                fps_str = f"~{frame_count / (now - last_fps_time):.1f} fps"
                frame_count = 0
                last_fps_time = now

            key = cv2.waitKey(200) & 0xFF
            if key == ord('q'):
                break
            elif key == ord('r'):
                cv2.destroyAllWindows()
                region = select_region()
                cv2.namedWindow(win_name, cv2.WINDOW_NORMAL)
                last_capture = 0.0
            elif key == ord('f'):
                white_bottom = not white_bottom
                last_capture = 0.0

    finally:
        analysis_queue.put(None)
        engine.quit()
        cv2.destroyAllWindows()
        print("Beendet.")


if __name__ == "__main__":
    main()
