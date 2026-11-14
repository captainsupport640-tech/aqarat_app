import '../app_imports.dart';

class PropertyFilterBar extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  const PropertyFilterBar({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    List filterOptions = ['الكل', ...AppDropdowns.propertyTypes];
    String safeValue = filterOptions.contains(selectedFilter) ? selectedFilter : 'الكل';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.amberAccent, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('فلتر نوع العقار: ', style: TextStyle(color: Colors.amberAccent, fontSize: 12)),
          const SizedBox(width: 6),
          DropdownButton<String>(
            value: safeValue,
            dropdownColor: const Color(0xFF1E1E1E),
            style: const TextStyle(color: Colors.white, fontSize: 12),
            underline: const SizedBox.shrink(),
            items: filterOptions.map((prop) {
              return DropdownMenuItem<String>(
                value: prop.toString(),
                child: Text(prop.toString(), style: const TextStyle(color: Colors.white)),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                onFilterChanged(val);
              }
            },
          ),
        ],
      ),
    );
  }
}