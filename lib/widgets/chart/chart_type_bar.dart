import 'package:flutter/material.dart';
import '../../controllers/chart_controller.dart';
import '../../models/chart_types.dart';

class ChartTypeBar extends StatelessWidget {
  final ChartController controller;

  const ChartTypeBar({super.key, required this.controller});

  static const _minuteOptions = [
    (value: 1, label: '1분'),
    (value: 3, label: '3분'),
    (value: 5, label: '5분'),
    (value: 10, label: '10분'),
    (value: 15, label: '15분'),
    (value: 30, label: '30분'),
    (value: 45, label: '45분'),
    (value: 60, label: '60분'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: const Color(0xFF0D1117),
      child: Row(
        children: [
          // 일봉 버튼
          _chartTypeButton(context, '일', ChartType.daily),
          const SizedBox(width: 8),
          // 분봉 버튼 + 드롭다운
          _chartTypeButton(
            context,
            '분',
            ChartType.minute,
            trailing: controller.chartType == ChartType.minute
                ? _buildMinuteDropdown()
                : null,
          ),
        ],
      ),
    );
  }

  Widget _chartTypeButton(
    BuildContext context,
    String label,
    ChartType type, {
    Widget? trailing,
  }) {
    final isSelected = controller.chartType == type;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => controller.setChartType(type),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF0F3460)
                  : const Color(0xFF16213E),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF4FC3F7)
                    : Colors.transparent,
                width: 1,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF4FC3F7) : Colors.grey[500],
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing],
      ],
    );
  }

  Widget _buildMinuteDropdown() {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF0F3460), width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: controller.minuteScope,
          dropdownColor: const Color(0xFF16213E),
          style: const TextStyle(color: Color(0xFF4FC3F7), fontSize: 11),
          icon: const Icon(
            Icons.arrow_drop_down,
            color: Color(0xFF4FC3F7),
            size: 16,
          ),
          isDense: true,
          items: _minuteOptions.map((opt) {
            return DropdownMenuItem<int>(
              value: opt.value,
              child: Text(opt.label),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              controller.setMinuteScope(value);
            }
          },
        ),
      ),
    );
  }
}
