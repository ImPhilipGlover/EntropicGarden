import sys
import datetime
import re
from PyQt6.QtWidgets import (QApplication, QWidget, QLabel, QTextEdit, 
                             QPushButton, QGridLayout, QFrame, QVBoxLayout, 
                             QHBoxLayout, QSlider, QTabWidget, QListWidget, QListWidgetItem, QToolTip)
from PyQt6.QtGui import QIcon, QColor, QTextCursor, QFont, QPalette
from PyQt6.QtCore import Qt, QThread, QObject, pyqtSignal
import html # Import the html module for escaping

# Import the corrected engine logic
from engine_logic_draft import AlchemyEngine, EngineSignals

class Worker(QObject):
    """Manages the AlchemyEngine in a separate thread."""
    def __init__(self, signals_instance):
        super().__init__()
        self.signals = signals_instance
        self.engine = AlchemyEngine(self.signals)

    def run(self): self.engine.run()
    def toggle_pause(self): self.engine.toggle_pause()
    def update_chaos(self, value): self.engine.update_chaos(value)
    def add_user_input(self, text): self.engine.add_user_input(text)
    def stop(self): self.engine.stop()

class EngineRoom(QWidget):
    """The main GUI window for the BRICKman & ROBIN Engine."""
    def __init__(self):
        super().__init__()
        self.thread = None
        self.worker = None
        self.engine_signals = EngineSignals()
        self.initUI()
        
    def _create_control_panel(self):
        control_panel = QFrame(self)
        control_panel.setFrameShape(QFrame.Shape.StyledPanel)
        panel_layout = QVBoxLayout()
        
        button_layout = QHBoxLayout()
        self.start_button = QPushButton("🚀 START ENGINE")
        self.pause_button = QPushButton("⏸️ PAUSE")
        self.stop_button = QPushButton("🛑 SHUTDOWN")
        self.pause_button.setEnabled(False)
        self.stop_button.setEnabled(False)
        button_layout.addWidget(self.start_button)
        button_layout.addWidget(self.pause_button)
        button_layout.addWidget(self.stop_button)
        
        slider_layout = QHBoxLayout()
        slider_layout.addWidget(QLabel("🌀 Chaos:"))
        self.chaos_slider = QSlider(Qt.Orientation.Horizontal)
        self.chaos_slider.setRange(0, 100); self.chaos_slider.setValue(15)
        self.chaos_value_label = QLabel("15%")
        slider_layout.addWidget(self.chaos_slider)
        slider_layout.addWidget(self.chaos_value_label)

        panel_layout.addLayout(button_layout)
        panel_layout.addLayout(slider_layout)

        status_info_layout = QGridLayout()
        self.mode_label = QLabel("<b>Mode:</b> N/A")
        self.theme_label = QLabel("<b>Theme:</b> N/A")
        self.sentiment_label = QLabel("<b>Sentiment:</b> neutral")
        self.cycle_label = QLabel("<b>Cycle:</b> 0/7")
        self.engine_status_display_label = QLabel("Engine Status: <b>Stopped</b>")
        status_info_layout.addWidget(self.mode_label, 0, 0)
        status_info_layout.addWidget(self.theme_label, 1, 0)
        status_info_layout.addWidget(self.sentiment_label, 0, 1)
        status_info_layout.addWidget(self.cycle_label, 1, 1)
        status_info_layout.addWidget(self.engine_status_display_label, 2, 0, 1, 2)

        panel_layout.addLayout(status_info_layout)
        control_panel.setLayout(panel_layout)
        return control_panel
        
    def initUI(self):
        self.setWindowTitle('BRICKman & ROBIN - The Engine Room v3.2 (Moderated Flow)')
        self.setGeometry(100, 100, 1600, 1000)
        self.setStyleSheet("background-color: #2B2B2B; color: #D3D3D3; font-size: 14px;")
        grid = QGridLayout(self)

        self.dialogue_pane = QTextEdit(self)
        self.dialogue_pane.setReadOnly(True)
        self.dialogue_pane.setStyleSheet("background-color: #212121; border: 1px solid #444; color: #EAEAEA; padding: 5px;")
        self.dialogue_pane.setFont(QFont("Segoe UI", 12))
        grid.addWidget(self.dialogue_pane, 0, 0)

        self.right_tabs = QTabWidget(self)
        self.right_tabs.setStyleSheet("QTabBar::tab { background: #3C3F41; color: #D3D3D3; padding: 10px; } QTabBar::tab:selected { background: #555; border-top: 2px solid #DAA520; }")
        self.alfred_console = QTextEdit(self); self.alfred_console.setReadOnly(True)
        self.alfred_console.setStyleSheet("background-color: #1E1E1E; color: #9C9C9C; font-family: 'Courier New', monospace;")
        self.forge_list = QListWidget(self)
        self.forge_list.setStyleSheet("background-color: #1E1E1E; color: #DAA520; font-family: 'Consolas', monospace;")
        self.loom_pane = QTextEdit(self); self.loom_pane.setReadOnly(True)
        self.loom_pane.setStyleSheet("background-color: #1E1E1E; color: #E6E6FA; font-family: 'Georgia', serif;")
        
        self.right_tabs.addTab(self.alfred_console, "🔧 System Log")
        self.right_tabs.addTab(self.forge_list, "🔥 The Forge")
        self.right_tabs.addTab(self.loom_pane, "🌸 The Loom")
        grid.addWidget(self.right_tabs, 0, 1, 4, 1)

        control_panel = self._create_control_panel()
        grid.addWidget(control_panel, 1, 0)
        
        self.brick_thought_pane = QTextEdit(self); self.brick_thought_pane.setReadOnly(True)
        self.brick_thought_pane.setStyleSheet("background-color: #21303D; border: 1px dashed #444; color: #87CEEB; font-style: italic;")
        self.brick_thought_pane.setFixedHeight(40)
        grid.addWidget(self.brick_thought_pane, 2, 0)

        input_layout = QHBoxLayout()
        self.user_input = QTextEdit(self); self.user_input.setFixedHeight(80)
        self.user_input.setPlaceholderText("Your directive for BRICK & ROBIN...")
        self.send_button = QPushButton("SEND ▶")
        self.send_button.setFixedHeight(80); self.send_button.setStyleSheet("background-color: #4CAF50; color: white; font-weight: bold;")
        input_layout.addWidget(self.user_input)
        input_layout.addWidget(self.send_button)
        grid.addLayout(input_layout, 3, 0)
        
        grid.setColumnStretch(0, 3)
        grid.setColumnStretch(1, 1)
        grid.setRowStretch(0, 6)

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

        # Define colors for different roles
        colors = {
            "USER": "#FFFFFF",      # White for user
            "ALFRED": "#BDB76B",    # Dark Khaki for Alfred
            "ROBIN": "#FFB6C1",     # Light Pink for Robin (name label)
            "BRICK": "#87CEEB",     # Sky Blue for Brick (name label)
            "ASSISTANT": "#D3D3D3"  # Light Gray for general B&R messages
        }
        
        # Determine the color to use for the main role label (e.g., "ROBIN:")
        label_color = colors.get(role.upper(), colors["ASSISTANT"])
        
        # Determine the text color for the content itself
        content_color = colors["ASSISTANT"] # Default content color

        # HTML escape the text content to prevent rendering issues
        escaped_text = html.escape(text).replace('\n', '<br>') 

        # Process and display based on the 'role' directly from the signal
        if role.upper() == "USER":
            content_color = colors["USER"]
            # User messages aligned right, with background for clarity
            cursor.insertHtml(
                f'<div align="right" style="margin-bottom: 12px; margin-right: 5px;">'
                f'<span style="color:{content_color}; background-color:#3c3c3c; padding: 8px; border-radius: 10px;">{escaped_text}</span> '
                f'<b style="color:{label_color};">:{timestamp} YOU</b></div>'
            )
        elif role.upper() == "ALFRED":
            content_color = colors["ALFRED"]
            # ALFRED's messages are centered and distinct
            cursor.insertHtml(
                f'<div align="center" style="margin: 8px 0;"><span style="color:{content_color}; font-family: \'Times New Roman\', serif; font-style: italic; font-size:11px; background-color:#2a2a2a; padding: 2px 8px; border-radius: 4px;"><b>{timestamp} ALFRED:</b> {escaped_text}</span></div>'
            )
        elif role.upper() == "ROBIN":
            content_color = "#FFDAB9" # PeachPuff for Robin's content
            # Add sparkle to ROBIN's ecstatic exclamations
            display_text_with_sparkle = escaped_text
            if "Holy guacamole" in text or "Awesome!" in text: # Use original 'text' for keyword check
                display_text_with_sparkle = f"✨ {escaped_text} ✨"
            cursor.insertHtml(
                f'<div style="margin-bottom: 12px; margin-left:5px;">'
                f'<b style="color:{colors["ROBIN"]};">{timestamp} ROBIN:</b><br>'
                f'<span style="color:{content_color}; font-family: Georgia, serif; font-size:13pt;">{display_text_with_sparkle}</span></div>'
            )
        elif role.upper() == "BRICK":
            content_color = "#E0FFFF" # LightCyan for Brick's content
            cursor.insertHtml(
                f'<div style="margin-bottom: 12px; margin-left:5px;">'
                f'<b style="color:{colors["BRICK"]};">{timestamp} BRICK:</b><br>'
                f'<span style="color:{content_color}; font-family: Consolas, monospace; font-size:13pt;">{escaped_text}</span></div>'
            )
        else: # Generic 'assistant' messages (like intros or un-prefixed AI responses)
            # This 'else' should now be very rare if parsing is perfect, but kept as a fallback.
            content_color = colors["ASSISTANT"]
            cursor.insertHtml(
                f'<div style="margin-bottom:12px; margin-left:5px;">'
                f'<b style="color:{label_color};">{timestamp} B&R:</b><br>'
                f'<span style="color:{content_color}; font-size:13pt;">{escaped_text}</span></div>'
            )
        
        self.dialogue_pane.ensureCursorVisible()

    def update_alfred_console(self, message): self.alfred_console.append(message)
    def update_engine_status_display(self, status): self.engine_status_display_label.setText(f"Engine Status: <b>{status}</b>")
    def update_brick_thought_pane(self, thought_text): self.brick_thought_pane.setText(f"BRICK (Internal Monitor): {thought_text}")
    def update_mode_display(self, mode): self.mode_label.setText(f"<b>Mode:</b> {mode}")
    def update_theme_display(self, theme): self.theme_label.setText(f"<b>Theme:</b> {theme.split(':')[0]}")
    def update_sentiment_display(self, sentiment):
        colors = {"optimistic": "#90EE90", "skeptical": "#FFD700", "playful": "#FFC0CB", "challenging": "#FFA07A", "reflective": "#ADD8E6", "neutral": "#D3D3D3"}
        color = colors.get(sentiment.lower(), "#D3D3D3")
        self.sentiment_label.setText(f"<b>Sentiment:</b> <span style='color:{color};'>{sentiment.capitalize()}</span>")
    def update_cycle_display(self, current, total): self.cycle_label.setText(f"<b>Cycle:</b> {current}/{total}")
    def update_forge_pane(self, protocols):
        self.forge_list.clear()
        for protocol in protocols:
            item_text = f"{protocol.get('name', 'N/A')} (v{protocol.get('version', 'N/A')})"
            list_item = QListWidgetItem(item_text)
            QToolTip.setFont(QFont('SansSerif', 10))
            list_item.setToolTip(f"<p style='white-space:pre-wrap; width:300px;'>{protocol.get('description', 'No description.')}</p>")
            self.forge_list.addItem(list_item)
    def update_loom_pane(self, metaphor): self.loom_pane.append(f"{metaphor}\n---\n")

    def start_engine(self):
        if self.thread and self.thread.isRunning(): return
        self.thread = QThread()
        self.worker = Worker(self.engine_signals)
        self.worker.moveToThread(self.thread)
        # Connect all signals
        self.engine_signals.dialogue_signal.connect(self.update_dialogue)
        self.engine_signals.alfred_signal.connect(self.update_alfred_console) 
        self.engine_signals.engine_status_signal.connect(self.update_engine_status_display)
        self.engine_signals.brick_thought_signal.connect(self.update_brick_thought_pane)
        self.engine_signals.mode_changed_signal.connect(self.update_mode_display)
        self.engine_signals.theme_changed_signal.connect(self.update_theme_display)
        self.engine_signals.sentiment_changed_signal.connect(self.update_sentiment_display)
        self.engine_signals.cycle_updated_signal.connect(self.update_cycle_display)
        self.engine_signals.forge_updated_signal.connect(self.update_forge_pane)
        self.engine_signals.loom_updated_signal.connect(self.update_loom_pane)
        
        self.thread.started.connect(self.worker.run)
        self.thread.finished.connect(self.thread.deleteLater)
        self.thread.start()
        self.start_button.setEnabled(False); self.stop_button.setEnabled(True); self.pause_button.setEnabled(True)

    def send_user_input(self):
        user_text = self.user_input.toPlainText().strip()
        if self.worker and user_text:
            self.worker.add_user_input(user_text)
            self.user_input.clear()

    def toggle_pause_engine(self):
        if self.worker:
            self.worker.toggle_pause()
            self.pause_button.setText("▶️ RESUME" if self.worker.is_paused else "⏸️ PAUSE")

    def stop_engine(self):
        if self.worker:
            self.worker.stop()
            self.thread.quit()
            self.thread.wait()
        self.start_button.setEnabled(True)
        self.pause_button.setEnabled(False); self.pause_button.setText("⏸️ PAUSE")
        self.stop_button.setEnabled(False)
        self.update_engine_status_display("Stopped")

    def update_chaos_value_display(self, value): self.chaos_value_label.setText(f"{value}%")
    def _update_worker_chaos(self, value):
        if self.worker: self.worker.update_chaos(value)
    def closeEvent(self, event):
        self.stop_engine()
        event.accept()

def main():
    app = QApplication(sys.argv)
    app.setStyle("Fusion")
    ex = EngineRoom()
    sys.exit(app.exec())

if __name__ == '__main__':
    main()