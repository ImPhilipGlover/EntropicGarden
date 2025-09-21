import sys
import time
import datetime
import re
from PyQt6.QtWidgets import (QApplication, QWidget, QLabel, QTextEdit, 
                             QPushButton, QGridLayout, QFrame, QVBoxLayout, 
                             QHBoxLayout, QSlider)
from PyQt6.QtGui import QIcon, QColor, QTextCursor, QFont
from PyQt6.QtCore import Qt, QThread, QObject, pyqtSignal

# Import EngineSignals directly from engine_logic
from engine_logic import AlchemyEngine, EngineSignals

class Worker(QObject):
    """Manages the AlchemyEngine in a separate thread."""
    def __init__(self, signals_instance):
        super().__init__()
        self.signals = signals_instance
        self.engine = AlchemyEngine(self.signals)

    def run(self):
        self.engine.run()

    def toggle_pause(self):
        self.engine.toggle_pause()

    def update_chaos(self, value):
        self.engine.update_chaos(value)
        
    def add_user_input(self, text):
        self.engine.add_user_input(text)
        
    def stop(self):
        self.engine.stop()

class EngineRoom(QWidget):
    """The main GUI window for the BRICKman & ROBIN Engine."""
    def __init__(self):
        super().__init__()
        self.thread = None
        self.worker = None
        self.engine_signals = EngineSignals()
        self.initUI()

    def _create_control_panel(self):
        control_panel = QFrame(self); control_panel.setFrameShape(QFrame.Shape.StyledPanel)
        control_panel.setStyleSheet("border: 1px solid #444; padding: 5px;")
        panel_layout = QVBoxLayout(); button_layout = QHBoxLayout()
        
        self.start_button = QPushButton("[ START ENGINE ]")
        self.pause_button = QPushButton("[ PAUSE ]")
        self.stop_button = QPushButton("[ SHUTDOWN ]")
        
        self.pause_button.setEnabled(False)
        self.stop_button.setEnabled(False)
        
        button_layout.addWidget(self.start_button)
        button_layout.addWidget(self.pause_button)
        button_layout.addWidget(self.stop_button)
        
        slider_layout = QHBoxLayout()
        chaos_label = QLabel("Chaos Probability:")
        self.chaos_slider = QSlider(Qt.Orientation.Horizontal)
        self.chaos_slider.setRange(0, 100)
        self.chaos_slider.setValue(15)
        self.chaos_value_label = QLabel("15%")
        
        slider_layout.addWidget(chaos_label)
        slider_layout.addWidget(self.chaos_slider)
        slider_layout.addWidget(self.chaos_value_label)

        panel_layout.addLayout(button_layout)
        panel_layout.addLayout(slider_layout)

        status_info_layout = QGridLayout()
        self.mode_label = QLabel("Mode: N/A")
        self.theme_label = QLabel("Theme: N/A")
        self.sentiment_label = QLabel("Sentiment: N/A")
        self.cycle_label = QLabel("Cycle: N/A")
        self.engine_status_display_label = QLabel("Engine Status: Stopped")

        status_info_layout.addWidget(self.mode_label, 0, 0)
        status_info_layout.addWidget(self.theme_label, 1, 0)
        status_info_layout.addWidget(self.sentiment_label, 0, 1)
        status_info_layout.addWidget(self.cycle_label, 1, 1)
        status_info_layout.addWidget(self.engine_status_display_label, 2, 0, 1, 2)

        panel_layout.addLayout(status_info_layout)

        control_panel.setLayout(panel_layout)
        return control_panel

    def initUI(self):
        self.setWindowTitle('BRICKman & ROBIN - The Engine Room v1.0 (LIVE)')
        self.setGeometry(100, 100, 1400, 900)
        self.setStyleSheet("background-color: #2B2B2B; color: #D3D3D3; font-size: 14px;")
        grid = QGridLayout(); self.setLayout(grid)
        
        self.dialogue_pane = QTextEdit(self)
        self.dialogue_pane.setReadOnly(True)
        self.dialogue_pane.setStyleSheet("background-color: #1E1E1E; border: 1px solid #444; color: #EAEAEA;")
        self.dialogue_pane.setFont(QFont("Consolas", 12))
        grid.addWidget(self.dialogue_pane, 0, 0, 1, 2)
        
        self.alfred_console = QTextEdit(self)
        self.alfred_console.setReadOnly(True)
        self.alfred_console.setStyleSheet("background-color: #252526; border: 1px solid #444; color: #9C9C9C; font-family: 'Consolas', 'Courier New', monospace;")
        self.alfred_console.setFont(QFont("Consolas", 10))
        grid.addWidget(self.alfred_console, 0, 2, 4, 1)

        control_panel = self._create_control_panel()
        grid.addWidget(control_panel, 1, 0, 1, 2)
        
        self.brick_thought_pane = QTextEdit(self)
        self.brick_thought_pane.setReadOnly(True)
        self.brick_thought_pane.setStyleSheet("background-color: #21303D; border: 1px solid #444; color: #87CEEB; font-style: italic; font-size: 11px;")
        self.brick_thought_pane.setFixedHeight(40)
        grid.addWidget(self.brick_thought_pane, 2, 0, 1, 2)

        input_layout = QHBoxLayout()
        self.user_input = QTextEdit(self)
        self.user_input.setFixedHeight(80)
        self.user_input.setStyleSheet("background-color: #1E1E1E; border: 1px solid #444; color: #EAEAEA;")
        self.user_input.setFont(QFont("Consolas", 12))
        self.send_button = QPushButton("SEND")
        self.send_button.setFixedHeight(80)
        input_layout.addWidget(self.user_input)
        input_layout.addWidget(self.send_button)
        grid.addLayout(input_layout, 3, 0, 1, 2)
        
        grid.setColumnStretch(1, 2)
        grid.setColumnStretch(2, 1)
        grid.setRowStretch(0, 6)
        grid.setRowStretch(1, 0)
        grid.setRowStretch(2, 0)
        grid.setRowStretch(3, 1)

        self.start_button.clicked.connect(self.start_engine)
        self.pause_button.clicked.connect(self.toggle_pause_engine)
        self.stop_button.clicked.connect(self.stop_engine)
        self.send_button.clicked.connect(self.send_user_input)
        self.chaos_slider.valueChanged.connect(self.update_chaos_value_display)
        self.chaos_slider.valueChanged.connect(self._update_worker_chaos)

        self.show()

    def update_dialogue(self, role, text):
        cursor = self.dialogue_pane.textCursor()
        cursor.movePosition(QTextCursor.MoveOperation.End)
        timestamp = datetime.datetime.now().strftime('%H:%M:%S')

        if role == "user":
            cursor.insertHtml(f'<span style="color:#B0C4DE;">[{timestamp}] YOU:</span> <span style="color:#B0C4DE;">{text}</span><br><br>')
        elif role == "ROBIN":
            # Apply ROBIN's specific styling
            cursor.insertHtml(f'<span style="color:#FFB6C1;">[{timestamp}] ROBIN:</span> <span style="color:#FFDAB9;">{text}</span><br><br>')
        elif role == "BRICK":
            # Apply BRICK's specific styling
            cursor.insertHtml(f'<span style="color:#87CEEB;">[{timestamp}] BRICK:</span> <span style="color:#ADD8E6;">{text}</span><br><br>')
        elif role == "BRICK_FORGE":
            # Apply specific styling for BRICK's Forge summaries
            cursor.insertHtml(f'<span style="color:#B0E0E6; font-weight: bold;">[{timestamp}] FORGE-BRICK:</span> <span style="color:#AFEEEE;">{text}</span><br><br>')
        else: # Fallback for general assistant messages or anything not specifically parsed
            cursor.insertHtml(f'<span style="color:#EAEAEA;">[{timestamp}] B&R:</span> <span style="color:#EAEAEA;">{text}</span><br><br>')

        self.dialogue_pane.setTextCursor(cursor)
        self.dialogue_pane.verticalScrollBar().setValue(self.dialogue_pane.verticalScrollBar().maximum())

    def update_alfred_console(self, message):
        self.alfred_console.append(message)
        self.alfred_console.verticalScrollBar().setValue(self.alfred_console.verticalScrollBar().maximum())

    def update_engine_status_display(self, status):
        self.engine_status_display_label.setText(f"Engine Status: {status}")

    def update_brick_thought_pane(self, thought_text):
        self.brick_thought_pane.clear()
        self.brick_thought_pane.setText(f"BRICK (Thought): {thought_text}")

    def update_mode_display(self, mode):
        self.mode_label.setText(f"Mode: {mode}")

    def update_theme_display(self, theme):
        self.theme_label.setText(f"Theme: {theme}")

    def update_sentiment_display(self, sentiment):
        self.sentiment_label.setText(f"Sentiment: {sentiment}")

    def update_cycle_display(self, current_cycle, total_cycles):
        self.cycle_label.setText(f"Cycle: {current_cycle}/{total_cycles}")

    def start_engine(self):
        if self.thread and self.thread.isRunning():
            self.alfred_console.append("ALFRED: Engine already running.")
            return

        self.thread = QThread()
        self.worker = Worker(self.engine_signals)
        self.worker.moveToThread(self.thread)
        
        self.engine_signals.dialogue_signal.connect(self.update_dialogue)
        self.engine_signals.alfred_signal.connect(self.update_alfred_console)
        self.engine_signals.engine_status_signal.connect(self.update_engine_status_display)
        self.engine_signals.brick_thought_signal.connect(self.update_brick_thought_pane)
        self.engine_signals.mode_changed_signal.connect(self.update_mode_display)
        self.engine_signals.theme_changed_signal.connect(self.update_theme_display)
        self.engine_signals.sentiment_changed_signal.connect(self.update_sentiment_display)
        self.engine_signals.cycle_updated_signal.connect(self.update_cycle_display)
        
        self.thread.started.connect(self.worker.run)
        self.thread.finished.connect(self.thread.deleteLater)
        self.thread.start()

        self.start_button.setEnabled(False)
        self.stop_button.setEnabled(True)
        self.pause_button.setEnabled(True)
        self.alfred_console.append("ALFRED: START signal received. Spooling up engine thread...")

    def send_user_input(self):
        user_text = self.user_input.toPlainText().strip()
        if self.worker and user_text:
            self.worker.add_user_input(user_text)
            self.user_input.clear()
        else:
            self.alfred_console.append("ALFRED: No engine running or no input detected.")

    def toggle_pause_engine(self):
        if self.worker:
            self.worker.toggle_pause()
            self.pause_button.setText("[ RESUME ]" if self.worker.engine.is_paused else "[ PAUSE ]")
        else:
            self.alfred_console.append("ALFRED: Engine not running to pause/resume.")

    def stop_engine(self):
        if self.worker:
            self.worker.stop()
            self.thread.quit()
            self.thread.wait()
        self.start_button.setEnabled(True)
        self.pause_button.setEnabled(False)
        self.stop_button.setEnabled(False)
        self.alfred_console.append("ALFRED: Engine thread terminated.")
        self.update_engine_status_display("Stopped")

    def update_chaos_value_display(self, value):
        self.chaos_value_label.setText(f"{value}%")

    def _update_worker_chaos(self, value):
        if self.worker:
            self.worker.update_chaos(value)

    def closeEvent(self, event):
        self.stop_engine()
        event.accept()

def main():
    app = QApplication(sys.argv)
    ex = EngineRoom()
    sys.exit(app.exec())

if __name__ == '__main__':
    main()