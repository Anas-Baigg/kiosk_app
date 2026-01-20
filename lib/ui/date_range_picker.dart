import 'package:flutter/material.dart';

class DateRangePicker extends StatelessWidget {
  final TextEditingController dateControllerFrom;
  final TextEditingController dateControllerTo;
  final VoidCallback onSelectDateFrom;
  final VoidCallback onSelectDateTo;
  final VoidCallback onTodayPressed;
  final VoidCallback onSearchPressed;

  const DateRangePicker({
    super.key,
    required this.dateControllerFrom,
    required this.dateControllerTo,
    required this.onSelectDateFrom,
    required this.onSelectDateTo,
    required this.onTodayPressed,
    required this.onSearchPressed,
  });
  static const _labelStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    fontStyle: FontStyle.normal,
    fontFamily: "RobotoMono",
    color: Color.fromARGB(255, 55, 63, 81),
  );

  // Helper method for the two date input fields
  Widget _buildDateFields() {
    return Column(
      children: [
        // DATE FROM FIELD
        TextField(
          controller: dateControllerFrom,
          decoration: const InputDecoration(
            labelText: "DATE FROM",
            filled: true,
            prefixIcon: Icon(Icons.calendar_today),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.blueGrey),
            ),
          ),
          readOnly: true,
          onTap: onSelectDateFrom,
        ),

        const SizedBox(height: 10),

        // DATE TO FIELD
        TextField(
          controller: dateControllerTo,
          decoration: const InputDecoration(
            labelText: "DATE TO",
            filled: true,
            prefixIcon: Icon(Icons.calendar_today),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.blueGrey),
            ),
          ),
          readOnly: true,
          onTap: onSelectDateTo,
        ),
      ],
    );
  }

  Widget _buildNarrowLayout() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Row 1: Date From and Date To (side-by-side)
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: dateControllerFrom,
                decoration: const InputDecoration(
                  labelText: "DATE FROM",
                  filled: true,
                  prefixIcon: Icon(Icons.calendar_today),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueGrey),
                  ),
                ),
                readOnly: true,
                onTap: onSelectDateFrom,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: dateControllerTo,
                decoration: const InputDecoration(
                  labelText: "DATE TO",
                  filled: true,
                  prefixIcon: Icon(Icons.calendar_today),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueGrey),
                  ),
                ),
                readOnly: true,
                onTap: onSelectDateTo,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Row 2: Today and Search Buttons (side-by-side)
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 50, // Standard button height
                child: ElevatedButton(
                  style: ButtonStyle(
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    padding: WidgetStateProperty.all(
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                    ),
                  ),
                  onPressed: onTodayPressed,
                  child: const Text("Today", style: _labelStyle),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 50, // Standard button height
                child: ElevatedButton(
                  style: ButtonStyle(
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    padding: WidgetStateProperty.all(
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                    ),
                  ),
                  onPressed: onSearchPressed,
                  child: const Text("Search", style: _labelStyle),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Layout for wide screens (Tablets/Horizontal) - Keeps the previous clean, wider layout
  Widget _buildWideLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date Fields take up most of the space
        Expanded(
          flex: 4,
          child: _buildDateFields(), // Reuse the stacked date fields helper
        ),

        const SizedBox(width: 15),

        // Buttons stacked vertically on the right
        Expanded(
          flex: 2,
          child: Column(
            children: [
              SizedBox(
                height: 55,
                width: double.infinity,
                child: ElevatedButton(
                  style: ButtonStyle(
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    padding: WidgetStateProperty.all(
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                    ),
                  ),
                  onPressed: onTodayPressed,
                  child: const Text("Today", style: _labelStyle),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 55,
                width: double.infinity,
                child: ElevatedButton(
                  style: ButtonStyle(
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    padding: WidgetStateProperty.all(
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                    ),
                  ),
                  onPressed: onSearchPressed,
                  child: const Text("Search", style: _labelStyle),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Define your breakpoint
        const double tabletBreakpoint = 600;

        if (constraints.maxWidth > tabletBreakpoint) {
          return _buildWideLayout();
        } else {
          return _buildNarrowLayout();
        }
      },
    );
  }
}
