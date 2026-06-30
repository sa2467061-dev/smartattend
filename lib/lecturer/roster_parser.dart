import 'dart:io';
import 'package:excel/excel.dart' as xls;
import 'package:csv/csv.dart';

/// Parses a student roster file (.xlsx or .csv) and extracts a flat list
/// of candidate matrix numbers. Does NOT touch Firestore — pure parsing.
class RosterParser {
  /// Matrix numbers are assumed alphanumeric, 5-15 characters, with at
  /// least one digit. Loose enough to survive a letter-prefixed format
  /// later, while still excluding obvious text like "Matrix No" or names.
  static final RegExp _matrixPattern = RegExp(r'^[A-Za-z]{0,4}\d{4,12}$');

  /// Returns the extracted matrix numbers (deduplicated, trimmed, uppercased).
  /// Throws a descriptive Exception if the file can't be parsed or no
  /// plausible matrix-number column is found.
  static Future<List<String>> extractMatrixNumbers(File file) async {
    final ext = file.path.split('.').last.toLowerCase();
    final List<List<String>> rows;

    if (ext == 'xlsx') {
      rows = await _readXlsx(file);
    } else if (ext == 'csv') {
      rows = await _readCsv(file);
    } else {
      throw Exception('Unsupported file type: .$ext. Please upload .xlsx or .csv.');
    }

    if (rows.isEmpty) {
      throw Exception('The file appears to be empty.');
    }

    final columnIndex = _detectMatrixColumn(rows);
    if (columnIndex == -1) {
      throw Exception(
          'Could not find a column that looks like matrix numbers. '
          'Make sure one column contains student ID / matrix numbers.');
    }

    final startRow = _looksLikeHeader(rows, columnIndex) ? 1 : 0;

    final Set<String> matrixNumbers = {};
    for (int i = startRow; i < rows.length; i++) {
      if (columnIndex >= rows[i].length) continue;
      final raw = rows[i][columnIndex].trim();
      if (raw.isEmpty) continue;
      matrixNumbers.add(raw.toUpperCase());
    }

    return matrixNumbers.toList();
  }

  static Future<List<List<String>>> _readXlsx(File file) async {
    final bytes = await file.readAsBytes();
    final excelFile = xls.Excel.decodeBytes(bytes);
    final sheet = excelFile.tables[excelFile.tables.keys.first];
    if (sheet == null) return [];

    return sheet.rows
        .map((row) => row.map((cell) => _cellToString(cell?.value)).toList())
        .toList();
  }

  /// Converts a cell value to a clean string. Excel stores ALL numbers as
  /// doubles internally (even whole numbers like matrix IDs), so a naive
  /// .toString() can produce "20242222334.0" instead of "20242222334".
  /// This strips that trailing ".0" so numeric matrix numbers match
  /// correctly against Firestore's string-stored matrix_no values.
  static String _cellToString(dynamic value) {
    if (value == null) return '';
    final str = value.toString();
    if (str.endsWith('.0')) {
      return str.substring(0, str.length - 2);
    }
    return str;
  }

  static Future<List<List<String>>> _readCsv(File file) async {
    final content = await file.readAsString();
    final rows = const CsvToListConverter().convert(content);
    return rows.map((row) => row.map((e) => e.toString()).toList()).toList();
  }

  /// Scans up to the first 20 data-ish rows and picks the column whose
  /// values most often match the matrix-number pattern.
  static int _detectMatrixColumn(List<List<String>> rows) {
    final sampleRows = rows.take(20).toList();
    if (sampleRows.isEmpty) return -1;

    final int maxCols = sampleRows.map((r) => r.length).reduce((a, b) => a > b ? a : b);
    int bestColumn = -1;
    int bestScore = 0;

    for (int col = 0; col < maxCols; col++) {
      int score = 0;
      for (final row in sampleRows) {
        if (col >= row.length) continue;
        if (_matrixPattern.hasMatch(row[col].trim())) score++;
      }
      if (score > bestScore) {
        bestScore = score;
        bestColumn = col;
      }
    }

    return bestScore > 0 ? bestColumn : -1;
  }

  /// If row 0's value in the detected column does NOT match the matrix
  /// pattern, it's almost certainly a header label like "Matrix No".
  static bool _looksLikeHeader(List<List<String>> rows, int columnIndex) {
    if (rows.isEmpty || columnIndex >= rows[0].length) return false;
    return !_matrixPattern.hasMatch(rows[0][columnIndex].trim());
  }
}