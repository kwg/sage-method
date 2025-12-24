#!/usr/bin/env python3
"""
md2pdf.py - Convert Markdown files to PDF

SAGE Utility Script for generating PDF reports from Markdown.
Works in NixOS environments using uvx for dependency management.

Usage:
    # Basic usage (outputs to same directory as input)
    uvx --with fpdf2 python md2pdf.py report.md

    # Specify output path
    uvx --with fpdf2 python md2pdf.py report.md -o /path/to/output.pdf

    # Within nix develop environment
    nix develop --command uvx --with fpdf2 python sage/scripts/md2pdf.py input.md

Features:
    - Converts Markdown to formatted PDF
    - Supports headers (h1-h4), tables, code blocks, lists
    - Handles unicode characters gracefully
    - No system dependencies (pure Python via fpdf2)

Author: SAGE Framework
"""

import argparse
import os
import re
import sys
from pathlib import Path

try:
    from fpdf import FPDF
    from fpdf.enums import XPos, YPos
except ImportError:
    print("Error: fpdf2 not installed. Run with:")
    print("  uvx --with fpdf2 python md2pdf.py <input.md>")
    sys.exit(1)


class MarkdownPDF(FPDF):
    """PDF generator with header/footer support."""

    def __init__(self, title: str = "Document"):
        super().__init__()
        self.doc_title = title

    def header(self):
        self.set_font("Helvetica", "B", 9)
        self.set_text_color(128, 128, 128)
        self.cell(0, 8, self.doc_title, new_x=XPos.LMARGIN, new_y=YPos.NEXT, align="C")
        self.ln(2)

    def footer(self):
        self.set_y(-15)
        self.set_font("Helvetica", "", 8)
        self.set_text_color(128, 128, 128)
        self.cell(0, 10, f"Page {self.page_no()}/{{nb}}", align="C")


def clean_text(text: str) -> str:
    """Remove markdown formatting and normalize unicode."""
    # Remove bold/italic
    text = re.sub(r"\*\*(.*?)\*\*", r"\1", text)
    text = re.sub(r"\*(.*?)\*", r"\1", text)
    # Remove inline code
    text = re.sub(r"`(.*?)`", r"\1", text)
    # Normalize unicode
    replacements = {
        "\u2013": "-",   # en-dash
        "\u2014": "--",  # em-dash
        "\u2018": "'",   # left single quote
        "\u2019": "'",   # right single quote
        "\u201c": '"',   # left double quote
        "\u201d": '"',   # right double quote
        "\u2022": "*",   # bullet
        "\u2026": "...", # ellipsis
        "\u00a0": " ",   # non-breaking space
    }
    for char, replacement in replacements.items():
        text = text.replace(char, replacement)
    return text


def parse_table(lines: list[str]) -> list[list[str]]:
    """Parse markdown table lines into rows."""
    rows = []
    for line in lines:
        # Skip separator lines (|---|---|)
        if line.startswith("|") and not re.match(r"^\|[-:\s|]+\|$", line):
            cells = [c.strip() for c in line.split("|")[1:-1]]
            rows.append(cells)
    return rows


def convert_md_to_pdf(input_path: str, output_path: str, title: str = None) -> None:
    """Convert a markdown file to PDF."""
    input_file = Path(input_path)

    if not input_file.exists():
        raise FileNotFoundError(f"Input file not found: {input_path}")

    # Read content
    content = input_file.read_text(encoding="utf-8")

    # Extract title from first h1 if not provided
    if title is None:
        match = re.search(r"^# (.+)$", content, re.MULTILINE)
        title = match.group(1) if match else input_file.stem

    # Initialize PDF
    pdf = MarkdownPDF(title=clean_text(title))
    pdf.set_auto_page_break(auto=True, margin=15)
    pdf.add_page()
    pdf.set_left_margin(10)
    pdf.set_right_margin(10)

    lines = content.split("\n")
    i = 0
    in_code_block = False
    code_lines = []

    while i < len(lines):
        line = lines[i]
        pdf.set_x(10)

        # Code blocks
        if line.startswith("```"):
            if in_code_block:
                # Render code block
                pdf.set_font("Courier", "", 8)
                pdf.set_fill_color(245, 245, 245)
                for code_line in code_lines:
                    pdf.set_x(12)
                    # Truncate long lines
                    display_line = code_line[:90] + "..." if len(code_line) > 90 else code_line
                    pdf.cell(0, 4, display_line, new_x=XPos.LMARGIN, new_y=YPos.NEXT, fill=True)
                pdf.ln(3)
                code_lines = []
                in_code_block = False
            else:
                in_code_block = True
            i += 1
            continue

        if in_code_block:
            code_lines.append(line)
            i += 1
            continue

        # Tables
        if line.startswith("|"):
            table_lines = []
            while i < len(lines) and lines[i].startswith("|"):
                table_lines.append(lines[i])
                i += 1

            rows = parse_table(table_lines)
            if rows:
                col_count = len(rows[0])
                col_width = (pdf.w - 20) / col_count

                # Header row
                pdf.set_font("Helvetica", "B", 8)
                pdf.set_fill_color(220, 220, 220)
                for cell in rows[0]:
                    pdf.cell(col_width, 6, clean_text(cell[:28]), border=1, fill=True)
                pdf.ln()

                # Data rows
                pdf.set_font("Helvetica", "", 8)
                pdf.set_fill_color(255, 255, 255)
                for row in rows[1:]:
                    for cell in row:
                        pdf.cell(col_width, 5, clean_text(cell[:28]), border=1)
                    pdf.ln()
                pdf.ln(3)
            continue

        # Headers
        if line.startswith("# "):
            pdf.set_font("Helvetica", "B", 16)
            pdf.set_text_color(0, 0, 0)
            pdf.ln(5)
            pdf.multi_cell(0, 10, clean_text(line[2:]))
            pdf.ln(3)
        elif line.startswith("## "):
            pdf.set_font("Helvetica", "B", 13)
            pdf.set_text_color(0, 0, 0)
            pdf.ln(4)
            pdf.multi_cell(0, 8, clean_text(line[3:]))
            pdf.ln(2)
        elif line.startswith("### "):
            pdf.set_font("Helvetica", "B", 11)
            pdf.set_text_color(0, 0, 0)
            pdf.ln(3)
            pdf.multi_cell(0, 7, clean_text(line[4:]))
            pdf.ln(2)
        elif line.startswith("#### "):
            pdf.set_font("Helvetica", "B", 10)
            pdf.set_text_color(0, 0, 0)
            pdf.ln(2)
            pdf.multi_cell(0, 6, clean_text(line[5:]))
            pdf.ln(1)
        # Horizontal rule
        elif line.startswith("---"):
            pdf.ln(2)
            pdf.set_draw_color(200, 200, 200)
            pdf.line(10, pdf.get_y(), pdf.w - 10, pdf.get_y())
            pdf.ln(4)
        # Bullet list
        elif line.startswith("- "):
            pdf.set_font("Helvetica", "", 9)
            pdf.set_text_color(0, 0, 0)
            text = clean_text(line[2:])
            pdf.cell(5, 5, "*")
            pdf.multi_cell(0, 5, text)
        # Numbered list
        elif re.match(r"^\d+\. ", line):
            pdf.set_font("Helvetica", "", 9)
            pdf.set_text_color(0, 0, 0)
            text = clean_text(line)
            pdf.multi_cell(0, 5, text)
        # Regular paragraph
        elif line.strip():
            pdf.set_font("Helvetica", "", 9)
            pdf.set_text_color(0, 0, 0)
            text = clean_text(line)
            if text.strip():
                pdf.multi_cell(0, 5, text)
        # Empty line
        else:
            pdf.ln(2)

        i += 1

    # Save PDF
    pdf.output(output_path)
    print(f"Generated: {output_path}")


def main():
    parser = argparse.ArgumentParser(
        description="Convert Markdown files to PDF",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s report.md                    # Output: report.pdf (same directory)
  %(prog)s report.md -o output.pdf      # Specify output path
  %(prog)s report.md -t "My Report"     # Custom title in header

NixOS Usage:
  nix develop --command uvx --with fpdf2 python %(prog)s input.md
        """
    )
    parser.add_argument("input", help="Input Markdown file")
    parser.add_argument("-o", "--output", help="Output PDF path (default: same name as input with .pdf extension)")
    parser.add_argument("-t", "--title", help="Document title for header (default: extracted from first h1)")

    args = parser.parse_args()

    # Determine output path
    input_path = Path(args.input)
    if args.output:
        output_path = args.output
    else:
        output_path = str(input_path.with_suffix(".pdf"))

    try:
        convert_md_to_pdf(args.input, output_path, args.title)
    except FileNotFoundError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error generating PDF: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
