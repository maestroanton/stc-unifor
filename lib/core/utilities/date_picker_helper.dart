import 'package:flutter/material.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import '../design_system.dart';

class DatePickerHelper {
  static CalendarDatePicker2WithActionButtonsConfig _getConfig(
    CalendarDatePicker2Type type,
    String? cancelText,
    String? confirmText, {
    Color? selectedRangeHighlightColor,
  }) {
    return CalendarDatePicker2WithActionButtonsConfig(
      calendarType: type,
      selectedDayHighlightColor: AppDesignSystem.primary,
      selectedRangeHighlightColor: selectedRangeHighlightColor,
      closeDialogOnCancelTapped: true,
      firstDayOfWeek: 1,
      weekdayLabels: ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'],
      weekdayLabelTextStyle: AppDesignSystem.bodySmall.copyWith(
        color: AppDesignSystem.neutral600,
        fontWeight: FontWeight.w600,
      ),
      controlsTextStyle: AppDesignSystem.bodyMedium.copyWith(
        color: AppDesignSystem.neutral700,
        fontWeight: FontWeight.w600,
      ),
      centerAlignModePicker: true,
      customModePickerIcon: const SizedBox.shrink(),
      selectedDayTextStyle: AppDesignSystem.bodyMedium.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      dayTextStyle: AppDesignSystem.bodyMedium.copyWith(
        color: AppDesignSystem.neutral700,
      ),
      disabledDayTextStyle: AppDesignSystem.bodyMedium.copyWith(
        color: AppDesignSystem.neutral300,
      ),
      todayTextStyle: AppDesignSystem.bodyMedium.copyWith(
        color: AppDesignSystem.primary,
        fontWeight: FontWeight.w600,
      ),
      yearTextStyle: AppDesignSystem.bodyMedium.copyWith(
        color: AppDesignSystem.neutral700,
      ),
      selectedYearTextStyle: AppDesignSystem.bodyMedium.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      dayBorderRadius: BorderRadius.circular(8),
      yearBorderRadius: BorderRadius.circular(8),
      buttonPadding: const EdgeInsets.symmetric(
        horizontal: AppDesignSystem.spacing16,
        vertical: AppDesignSystem.spacing8,
      ),
      cancelButtonTextStyle: AppDesignSystem.bodyMedium.copyWith(
        color: AppDesignSystem.neutral600,
      ),
      okButtonTextStyle: AppDesignSystem.bodyMedium.copyWith(
        color: AppDesignSystem.primary,
        fontWeight: FontWeight.w600,
      ),
      cancelButton: Text(
        cancelText ?? 'Cancelar',
        style: AppDesignSystem.bodyMedium.copyWith(
          color: AppDesignSystem.neutral600,
        ),
      ),
      okButton: Text(
        confirmText ?? 'Confirmar',
        style: AppDesignSystem.bodyMedium.copyWith(
          color: AppDesignSystem.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static Future<DateTime?> showDatePicker({
    required BuildContext context,
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
    String? helpText,
    String? cancelText,
    String? confirmText,
  }) async {
    final config = _getConfig(
      CalendarDatePicker2Type.single,
      cancelText,
      confirmText,
    );

    final results = await showCalendarDatePicker2Dialog(
      context: context,
      config: config,
      dialogSize: const Size(325, 400),
      borderRadius: BorderRadius.circular(AppDesignSystem.radiusL),
      value: initialDate != null ? [initialDate] : [],
      dialogBackgroundColor: AppDesignSystem.surface,
    );

    return results?.isNotEmpty == true ? results!.first : null;
  }

  static Future<DateTimeRange?> showDateRangePicker({
    required BuildContext context,
    DateTimeRange? initialRange,
    DateTime? firstDate,
    DateTime? lastDate,
    String? helpText,
    String? cancelText,
    String? confirmText,
  }) async {
    final config = _getConfig(
      CalendarDatePicker2Type.range,
      cancelText,
      confirmText,
      selectedRangeHighlightColor: AppDesignSystem.primary.withValues(
        alpha: 0.1,
      ),
    );

    final List<DateTime?> initialDates = [];
    if (initialRange != null) {
      initialDates.addAll([initialRange.start, initialRange.end]);
    }

    final results = await showCalendarDatePicker2Dialog(
      context: context,
      config: config,
      dialogSize: const Size(325, 400),
      borderRadius: BorderRadius.circular(AppDesignSystem.radiusL),
      value: initialDates,
      dialogBackgroundColor: AppDesignSystem.surface,
    );

    if (results != null && results.length >= 2) {
      final start = results[0];
      final end = results[1];
      if (start != null && end != null) {
        return DateTimeRange(start: start, end: end);
      }
    }

    return null;
  }

  static String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  static DateTime? parseDate(String dateString) {
    try {
      final parts = dateString.split('/');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  static DateTimeRange getDefaultRange() {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    return DateTimeRange(start: thirtyDaysAgo, end: now);
  }

  static bool isValidDateFormat(String dateString) {
    if (dateString.isEmpty) return true;
    final regex = RegExp(r'^\d{2}/\d{2}/\d{4}$');
    if (!regex.hasMatch(dateString)) return false;
    return parseDate(dateString) != null;
  }
}