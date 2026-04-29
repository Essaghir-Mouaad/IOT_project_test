# Vitals History Screen — Complete Implementation Guide

## Overview
The `SensorsHistory` widget provides a comprehensive vitals analytics dashboard with two tabbed views (Per-Entry and Summary) displaying health metrics from Firebase Realtime Database.

---

## Architecture & Data Flow

### File Structure
```
lib/screens/home/components/sensors_history.dart
├── SensorsHistory (StatefulWidget)
├── _SensorsHistoryState (State)
├── _PerEntryView (Per-entry charts view)
├── _SummaryView (Summary analytics view)
├── [Chart Classes - 7 total]
├── [Helper Widgets]
└── [Data Models]
```

### Data Pipeline
```
SensorsHistory (widget entry point)
    ↓
_SensorsHistoryState (state management)
    ↓
_loadHistory() → _fetchVitalsHistory()
    ↓
Firebase: vitals/{deviceId}/history
    ↓
VitalDataModel.fromMap() → List<VitalDataModel>
    ↓
_HistoryData (container model)
    ↓
TabBarView routes to: _PerEntryView | _SummaryView
    ↓
7 Different Chart Types
```

---

## Main Classes & Functions

### 1. **SensorsHistory (StatefulWidget)**
```dart
class SensorsHistory extends StatefulWidget {
  final String deviceId;      // Target device ID
  final DatabaseService db;   // Database reference
  
  const SensorsHistory({super.key, required this.deviceId, required this.db});
  
  @override
  State<SensorsHistory> createState() => _SensorsHistoryState();
}
```
**Purpose**: Entry point widget that receives device ID and database service from parent.

**Parameters**:
- `deviceId`: Identifies which device's vitals to fetch
- `db`: DatabaseService instance for Firebase operations

---

### 2. **_SensorsHistoryState (State with SingleTickerProviderStateMixin)**

#### Fields
```dart
late Future<_HistoryData> _historyFuture;  // Async vitals fetch
late TabController _tabController;         // Tab switching controller
```

#### **initState()**
```dart
@override
void initState() {
  super.initState();
  _historyFuture = _loadHistory();
  _tabController = TabController(length: 2, vsync: this);
}
```
**Purpose**: Initialize state when widget mounts.

**What it does**:
1. Triggers `_loadHistory()` which fetches vitals from Firebase
2. Creates `TabController` with 2 tabs (Per-Entry, Summary) for tab switching

---

#### **dispose()**
```dart
@override
void dispose() {
  _tabController.dispose();
  super.dispose();
}
```
**Purpose**: Clean up resources when widget is destroyed.

**What it does**: Disposes the TabController to free memory.

---

#### **_loadHistory()**
```dart
Future<_HistoryData> _loadHistory() async {
  final vitals = await _fetchVitalsHistory();
  return _HistoryData(vitals: vitals);
}
```
**Purpose**: Orchestrate vitals data loading.

**Return**: `_HistoryData` object containing list of vital readings.

**Flow**:
1. Calls `_fetchVitalsHistory()` to get raw vitals
2. Wraps result in `_HistoryData` model
3. Returns for use in FutureBuilder

---

#### **_fetchVitalsHistory()**
```dart
Future<List<VitalDataModel>> _fetchVitalsHistory() async {
  final raw = await widget.db.getVitalsHistory(widget.deviceId, limit: 120);
  return raw
      .asMap()
      .entries
      .map(
        (entry) => VitalDataModel.fromMap('hist_${entry.key}', entry.value),
      )
      .toList();
}
```
**Purpose**: Fetch and parse vitals from Firebase.

**Parameters**:
- `limit: 120`: Fetch up to 120 recent entries (4 hours @ 2-min intervals)

**Process**:
1. `widget.db.getVitalsHistory()` → Returns `List<Map<String, dynamic>>`
2. `.asMap().entries` → Convert list to indexed map entries
3. `.map()` → For each entry, call `VitalDataModel.fromMap()` to parse
4. `.toList()` → Collect all parsed models

**Output**: `List<VitalDataModel>` ready for charts.

---

#### **build()**
```dart
@override
Widget build(BuildContext context) {
  return FutureBuilder<_HistoryData>(
    future: _historyFuture,
    builder: (context, snapshot) {
      // Handle 4 states: waiting, error, empty, data ready
    },
  );
}
```
**Purpose**: Main UI rendering with async state handling.

**States Handled**:

1. **Loading State** (`snapshot.connectionState == ConnectionState.waiting`)
   - Shows `Loading()` spinner while data fetches

2. **Error State** (`snapshot.hasError`)
   - Shows error message
   - Provides "Retry" button to reload

3. **Empty State** (`vitalsData.isEmpty`)
   - Shows "No vitals history available" message
   - Provides "Reload Data" button

4. **Success State** (data ready)
   - Shows `RefreshIndicator` wrapper
   - Renders `Column` with:
     - Tab selector (Per-Entry View / Summary)
     - `Expanded(child: TabBarView)` with two tabs
     - Each tab contains respective view widget

**Pull-to-Refresh**: `RefreshIndicator.onRefresh` triggers `setState(() { _historyFuture = _loadHistory(); })` to reload data.

---

## View Widgets

### 3. **_PerEntryView**
```dart
class _PerEntryView extends StatelessWidget {
  final List<VitalDataModel> vitals;
  const _PerEntryView({required this.vitals});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _SectionHeader(title: 'Per-Entry Vitals'),
          _HeartRateChart(vitals: vitals),
          _SpO2Chart(vitals: vitals),
          _BodyTemperatureChart(vitals: vitals),
          _RespiratoryRateChart(vitals: vitals),
          _BloodPressureChart(vitals: vitals),
        ],
      ),
    );
  }
}
```
**Purpose**: Display individual vital readings in 5 separate charts.

**Chart Order**:
1. Heart Rate (Line Chart)
2. SpO2 (Line Chart)
3. Body Temperature (Bar Chart)
4. Respiratory Rate (Line Chart)
5. Blood Pressure (Dual-Line Chart)

**Layout**: Vertical scrolling list of cards, each card shows single metric with stats row.

---

### 4. **_SummaryView**
```dart
class _SummaryView extends StatelessWidget {
  final List<VitalDataModel> vitals;
  const _SummaryView({required this.vitals});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _SectionHeader(title: 'Summary Statistics'),
          _NormalizedMetricsChart(vitals: vitals),
          _SpO2GaugeChart(vitals: vitals),
          _HeartRateHistogram(vitals: vitals),
          _BloodPressureGroupedChart(vitals: vitals),
        ],
      ),
    );
  }
}
```
**Purpose**: Display aggregated statistics across all vitals entries.

**Charts** (4 total):
1. Normalized Metrics (Horizontal Bar)
2. SpO2 Gauge (Donut Pie Chart)
3. Heart Rate Histogram (4 buckets)
4. Blood Pressure Grouped (Side-by-side bars)

---

## Chart Classes (7 Total)

### **5. _HeartRateChart**
```dart
class _HeartRateChart extends StatelessWidget {
  final List<VitalDataModel> vitals;
  const _HeartRateChart({required this.vitals});

  @override
  Widget build(BuildContext context) {
    if (vitals.isEmpty) return const SizedBox();
    
    // 1. Extract heartRate values from all entries
    final spots = vitals.asMap().entries
        .map((e) => fl_chart.FlSpot(e.key.toDouble(), e.value.heartRate))
        .toList();
    
    // 2. Calculate statistics
    final values = vitals.map((v) => v.heartRate).toList();
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final avg = values.reduce((a, b) => a + b) / values.length;
    
    // 3. Return Card with LineChart inside
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Title + Current Value badge
            Row(...),
            // LineChart with fill area
            SizedBox(
              height: 180,
              child: fl_chart.LineChart(...),
            ),
            // Stats row: Min/Max/Avg/Readings
            Row(children: [_StatItem(...), ...]),
          ],
        ),
      ),
    );
  }
}
```
**Chart Type**: **Line Chart with area fill**

**Color**: Red (`Colors.red[400]`)

**Data Points**: One point per heart rate reading

**Stats Row Shows**:
- Min: Minimum bpm value
- Max: Maximum bpm value
- Avg: Average bpm across all readings
- Readings: Total number of readings

**Y-Axis Range**: `min - 5` to `max + 5`

**Features**:
- Smooth curves
- Area fill below line (light red)
- Dot markers on each point

---

### **6. _SpO2Chart**
```dart
class _SpO2Chart extends StatelessWidget {
  // Similar structure to _HeartRateChart
  // Differences:
  // - Uses vitals.map((v) => v.spO2)
  // - Y-axis: 90% to 100% (fixed clinical range)
  // - Color: Green (Colors.green[500])
  // - Unit: %
}
```
**Chart Type**: **Line Chart with area fill**

**Color**: Green (`Colors.green[500]`)

**Y-Axis Range**: 90% to 100% (clinical normal range)

**Stats Row Shows**:
- Min, Max, Avg (in %), Readings count

**Interpretation**: Normal SpO2 is 95-100%. Below 90% indicates hypoxemia.

---

### **7. _BodyTemperatureChart**
```dart
class _BodyTemperatureChart extends StatelessWidget {
  final List<VitalDataModel> vitals;

  @override
  Widget build(BuildContext context) {
    if (vitals.isEmpty) return const SizedBox();
    
    // 1. Extract temperature values
    final values = vitals.map((v) => v.bodyTemp).toList();
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final avg = values.reduce((a, b) => a + b) / values.length;
    
    // 2. Create bar groups (one bar per entry)
    final barGroups = vitals
        .asMap()
        .entries
        .map((e) => fl_chart.BarChartGroupData(
          x: e.key,  // Index position on X-axis
          barRods: [
            fl_chart.BarChartRodData(
              toY: e.value.bodyTemp,
              color: Colors.orange[400],
              width: 8,
            ),
          ],
        ))
        .toList();
    
    return Card(...BarChart(barGroups)...);
  }
}
```
**Chart Type**: **Bar Chart**

**Color**: Orange (`Colors.orange[400]`)

**Data**: One vertical bar per entry, height = body temperature

**Stats Row Shows**:
- Min, Max, Avg (in °C), Readings count

**Y-Axis Range**: `min - 0.5` to `max + 0.5`

**Clinical Ranges**:
- Normal: 36.5–37.5°C
- Fever: > 38°C
- Hypothermia: < 36°C

---

### **8. _RespiratoryRateChart**
```dart
class _RespiratoryRateChart extends StatelessWidget {
  // Similar to _HeartRateChart
  // - Uses vitals.map((v) => v.respiratoryRate)
  // - Color: Blue (Colors.blue[400])
  // - Unit: rpm (breaths per minute)
}
```
**Chart Type**: **Line Chart** (no fill)

**Color**: Blue (`Colors.blue[400]`)

**Stats Row Shows**:
- Min, Max, Avg (in rpm), Readings count

**Normal Range**: 12–20 breaths per minute

---

### **9. _BloodPressureChart**
```dart
class _BloodPressureChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (vitals.isEmpty) return const SizedBox();
    
    // 1. Create two line data sets
    final systolicSpots = vitals
        .asMap()
        .entries
        .map((e) => fl_chart.FlSpot(e.key.toDouble(), e.value.systolicBP))
        .toList();

    final diastolicSpots = vitals
        .asMap()
        .entries
        .map((e) => fl_chart.FlSpot(e.key.toDouble(), e.value.diastolicBP))
        .toList();
    
    // 2. Return LineChart with TWO lines
    return Card(
      child: SizedBox(
        height: 180,
        child: fl_chart.LineChart(
          fl_chart.LineChartData(
            lineBarsData: [
              // Line 1: Systolic (solid purple)
              fl_chart.LineChartBarData(
                spots: systolicSpots,
                color: Colors.purple[400],
                barWidth: 2,
              ),
              // Line 2: Diastolic (dashed light purple)
              fl_chart.LineChartBarData(
                spots: diastolicSpots,
                color: Colors.purple[200],
                barWidth: 2,
                dashArray: [5, 5],  // Dashed pattern
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```
**Chart Type**: **Dual-Line Chart**

**Lines**:
1. **Systolic**: Solid purple (`Colors.purple[400]`)
2. **Diastolic**: Dashed purple (`Colors.purple[200]`) with `dashArray: [5, 5]`

**Stats Row Shows**:
- Systolic (mmHg)
- Diastolic (mmHg)
- Pulse Pressure = Systolic - Diastolic
- Readings count

**Clinical Interpretation**:
- Systolic > Diastolic (e.g., 120/80)
- Normal: < 120/80
- Hypertension: ≥ 130/80

---

## Summary Chart Classes (4 Total)

### **10. _NormalizedMetricsChart**
```dart
class _NormalizedMetricsChart extends StatelessWidget {
  final List<VitalDataModel> vitals;

  double _normalize(double value, double minRef, double maxRef) {
    // Formula: ((value - min) / (max - min)).clamp(0.0, 1.0) * 100
    return ((value - minRef) / (maxRef - minRef)).clamp(0.0, 1.0) * 100;
  }

  @override
  Widget build(BuildContext context) {
    if (vitals.isEmpty) return const SizedBox();
    
    // 1. Calculate mean for each metric
    final heartRateMean = vitals.map((v) => v.heartRate).reduce((a, b) => a + b) / vitals.length;
    final spo2Mean = vitals.map((v) => v.spO2).reduce((a, b) => a + b) / vitals.length;
    final bodyTempMean = vitals.map((v) => v.bodyTemp).reduce((a, b) => a + b) / vitals.length;
    final respRateMean = vitals.map((v) => v.respiratoryRate).reduce((a, b) => a + b) / vitals.length;
    final systolicBPMean = vitals.map((v) => v.systolicBP).reduce((a, b) => a + b) / vitals.length;
    
    // 2. Normalize each mean to 0-100 scale using clinical ranges
    final normHR = _normalize(heartRateMean, 40, 160);      // Clinical range: 40-160 bpm
    final normSpo2 = _normalize(spo2Mean, 80, 100);         // Clinical range: 80-100%
    final normTemp = _normalize(bodyTempMean, 35, 42);      // Clinical range: 35-42°C
    final normRespRate = _normalize(respRateMean, 8, 30);   // Clinical range: 8-30 rpm
    final normBP = _normalize(systolicBPMean, 80, 180);     // Clinical range: 80-180 mmHg
    
    // 3. Create 5 bar groups (one per metric)
    final barGroups = [
      fl_chart.BarChartGroupData(
        x: 0,
        barRods: [fl_chart.BarChartRodData(toY: normHR, color: Colors.red[400], width: 20)],
      ),
      fl_chart.BarChartGroupData(
        x: 1,
        barRods: [fl_chart.BarChartRodData(toY: normSpo2, color: Colors.green[500], width: 20)],
      ),
      // ... (3 more bars for Temp, RR, BP)
    ];
    
    return Card(
      child: SizedBox(
        height: 200,
        child: fl_chart.BarChart(
          fl_chart.BarChartData(maxY: 100, barGroups: barGroups),
        ),
      ),
    );
  }
}
```
**Chart Type**: **Horizontal Bar Chart**

**Purpose**: Compare all 5 metrics on single 0-100 normalized scale.

**Normalization Formula**:
```
normalized = ((value - minClinical) / (maxClinical - minClinical)) * 100
  .clamp(0.0, 1.0)  // Ensure result stays between 0-100%
```

**Clinical Ranges Used**:
| Metric | Min | Max | Unit |
|--------|-----|-----|------|
| Heart Rate | 40 | 160 | bpm |
| SpO2 | 80 | 100 | % |
| Body Temp | 35 | 42 | °C |
| Resp Rate | 8 | 30 | rpm |
| Systolic BP | 80 | 180 | mmHg |

**Colors**: Red, Green, Orange, Blue, Purple (one per metric)

**Interpretation**: 100 = upper limit of clinical range, 0 = lower limit.

---

### **11. _SpO2GaugeChart**
```dart
class _SpO2GaugeChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (vitals.isEmpty) return const SizedBox();
    
    // Calculate mean SpO2
    final meanSpo2 = vitals.map((v) => v.spO2).reduce((a, b) => a + b) / vitals.length;
    
    return Card(
      child: Column(
        children: [
          Text('SpO2 Gauge (Mean)'),
          // Donut chart with center space
          Container(
            constraints: BoxConstraints(maxHeight: 160, maxWidth: 160),
            child: fl_chart.PieChart(
              fl_chart.PieChartData(
                sections: [
                  // Green section = mean SpO2 percentage
                  fl_chart.PieChartSectionData(
                    value: meanSpo2,
                    color: Colors.green[500],
                    radius: 45,
                  ),
                  // Grey section = remainder to 100%
                  fl_chart.PieChartSectionData(
                    value: 100 - meanSpo2,
                    color: Colors.grey[200],
                    radius: 45,
                  ),
                ],
                centerSpaceRadius: 35,  // Creates donut hole
              ),
            ),
          ),
          // Display percentage in center
          Text(meanSpo2.toStringAsFixed(1) + '%'),
        ],
      ),
    );
  }
}
```
**Chart Type**: **Donut Pie Chart (PieChart with centerSpaceRadius)**

**Data**:
- Green segment: mean SpO2 value (e.g., 97%)
- Grey segment: remainder to 100% (e.g., 3%)

**Center Display**: Shows percentage value in large text

**Use Case**: Quick visual gauge of overall oxygen saturation.

---

### **12. _HeartRateHistogram**
```dart
class _HeartRateHistogram extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (vitals.isEmpty) return const SizedBox();
    
    // 1. Count readings in each BPM bucket
    final below60 = vitals.where((v) => v.heartRate < 60).length;
    final range60to80 = vitals.where((v) => v.heartRate >= 60 && v.heartRate < 80).length;
    final range80to100 = vitals.where((v) => v.heartRate >= 80 && v.heartRate < 100).length;
    final above100 = vitals.where((v) => v.heartRate >= 100).length;
    
    // 2. Create 4 bars (one per bucket)
    final barGroups = [
      fl_chart.BarChartGroupData(
        x: 0,
        barRods: [fl_chart.BarChartRodData(toY: below60.toDouble(), color: Colors.blue[300], width: 20)],
      ),
      fl_chart.BarChartGroupData(
        x: 1,
        barRods: [fl_chart.BarChartRodData(toY: range60to80.toDouble(), color: Colors.blue[500], width: 20)],
      ),
      fl_chart.BarChartGroupData(
        x: 2,
        barRods: [fl_chart.BarChartRodData(toY: range80to100.toDouble(), color: Colors.orange[400], width: 20)],
      ),
      fl_chart.BarChartGroupData(
        x: 3,
        barRods: [fl_chart.BarChartRodData(toY: above100.toDouble(), color: Colors.red[400], width: 20)],
      ),
    ];
    
    return Card(
      child: SizedBox(
        height: 200,
        child: fl_chart.BarChart(
          fl_chart.BarChartData(
            maxY: (vitals.length / 2).toDouble(),
            barGroups: barGroups,
          ),
        ),
      ),
    );
  }
}
```
**Chart Type**: **Histogram Bar Chart with 4 buckets**

**Buckets**:
| Bucket | Range | Color | Health Status |
|--------|-------|-------|----------------|
| <60 | Below 60 bpm | Light Blue | Bradycardia |
| 60-80 | 60 to 80 bpm | Medium Blue | Normal (Low) |
| 80-100 | 80 to 100 bpm | Orange | Normal (High) |
| >100 | Above 100 bpm | Red | Tachycardia |

**Y-Axis**: Count of readings in each bucket (max = total readings / 2)

**Use Case**: Identify distribution and abnormal heart rate patterns.

---

### **13. _BloodPressureGroupedChart**
```dart
class _BloodPressureGroupedChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (vitals.isEmpty) return const SizedBox();
    
    // 1. Create grouped bar data (systolic + diastolic side-by-side)
    final barGroups = vitals
        .asMap()
        .entries
        .map((e) => fl_chart.BarChartGroupData(
          x: e.key,  // One group per reading
          barRods: [
            // Systolic bar (darker purple)
            fl_chart.BarChartRodData(
              toY: e.value.systolicBP,
              color: Colors.purple[400],
              width: 6,
            ),
            // Diastolic bar (lighter purple), positioned next to systolic
            fl_chart.BarChartRodData(
              toY: e.value.diastolicBP,
              color: Colors.purple[200],
              width: 6,
            ),
          ],
        ))
        .toList();
    
    final allValues = [...vitals.map((v) => v.systolicBP), ...vitals.map((v) => v.diastolicBP)];
    final maxY = allValues.reduce((a, b) => a > b ? a : b) + 10;
    
    return Card(
      child: Column(
        children: [
          Text('Blood Pressure Over Time'),
          SizedBox(
            height: 220,
            width: double.infinity,
            child: fl_chart.BarChart(
              fl_chart.BarChartData(maxY: maxY, barGroups: barGroups),
            ),
          ),
          // Legend
          Row(
            children: [
              Text('Systolic', style: ...), // Purple[400]
              Text('Diastolic', style: ...), // Purple[200]
            ],
          ),
        ],
      ),
    );
  }
}
```
**Chart Type**: **Grouped Bar Chart**

**Data**:
- Each entry produces one group with 2 bars side-by-side:
  - **Bar 1 (Systolic)**: Dark purple, height = systolic value
  - **Bar 2 (Diastolic)**: Light purple, height = diastolic value

**X-Axis**: Reading index (0, 1, 2, ...)

**Y-Axis**: Pressure in mmHg, range 0 to max + 10

**Legend**: Shows which bar represents systolic vs. diastolic

**Use Case**: Track both systolic and diastolic trends over time simultaneously.

---

## Helper Widgets

### **14. _SectionHeader**
```dart
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
      ),
    );
  }
}
```
**Purpose**: Display section title (e.g., "Per-Entry Vitals", "Summary Statistics").

**Styling**: Bold 17pt text with left padding.

---

### **15. _StatItem**
```dart
class _StatItem extends StatelessWidget {
  final String label;   // e.g., "Min", "Max", "Avg"
  final String value;   // e.g., "72", "95.5"
  final String unit;    // e.g., "bpm", "%", "°C"

  const _StatItem({required this.label, required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label above
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        const SizedBox(height: 2),
        // Value + unit on same line
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              if (unit.isNotEmpty)
                TextSpan(
                  text: ' $unit',
                  style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
```
**Purpose**: Display single statistic (label above, value + unit below).

**Styling**:
- Label: 10pt grey
- Value: 12pt bold black
- Unit: 9pt grey

**Example Output**:
```
Min
72 bpm
```

---

## Data Model

### **16. _HistoryData**
```dart
class _HistoryData {
  final List<VitalDataModel> vitals;

  const _HistoryData({required this.vitals});
  const _HistoryData.empty() : vitals = const [];
}
```
**Purpose**: Container for vitals history data.

**Fields**:
- `vitals`: List of `VitalDataModel` objects (vital readings)

**Constructor**:
- `_HistoryData({required this.vitals})`: Regular constructor
- `_HistoryData.empty()`: Factory for empty data (used in initial state)

---

## Key Implementation Details

### **Fixed Layout Issues**
1. **Removed fixed height constraint** on TabBarView (was `SizedBox(height: MediaQuery.of(context).size.height)`)
   - Now uses `Expanded` for responsive layout
   
2. **Reduced SpO2 Gauge size**
   - Radius: 50 → Better fit
   - Center space: 55 → 40
   - Container max: 200x200 → 160x160

3. **Fixed Blood Pressure chart**
   - Added `reservedSize` for proper axis label spacing
   - Made width `double.infinity` for full card width
   - Increased height to 220 for better visibility

4. **Added margin to cards**
   - `margin: EdgeInsets.symmetric(horizontal: 12)` prevents edge overflow

### **Chart Library (fl_chart)**
All charts use `fl_chart` package with namespace alias: `import 'package:fl_chart/fl_chart.dart' as fl_chart;`

**Supported Chart Types Used**:
- `fl_chart.LineChart`: Heart Rate, SpO2, Respiratory Rate, Blood Pressure
- `fl_chart.BarChart`: Body Temperature, Normalized Metrics, Heart Rate Histogram, Blood Pressure Grouped
- `fl_chart.PieChart`: SpO2 Gauge

### **Color Scheme**
- **Red**: Heart Rate, Tachycardia (>100 bpm)
- **Green**: SpO2, Normal oxygen levels
- **Orange**: Temperature, Normal (High) heart rate, Abnormal patterns
- **Blue**: Respiratory Rate, Normal (Low) heart rate, Bradycardia
- **Purple**: Blood Pressure (systolic = dark, diastolic = light)
- **Grey**: Empty states, secondary data

### **Clinical Ranges**
| Metric | Min | Max | Unit |
|--------|-----|-----|------|
| Heart Rate | 40 | 160 | bpm |
| SpO2 | 80 | 100 | % |
| Body Temp | 35 | 42 | °C |
| Resp Rate | 8 | 30 | rpm |
| Systolic BP | 80 | 180 | mmHg |

---

## Performance Considerations

1. **Data Limit**: Fetches max 120 entries (~4 hours at 2-min intervals)
2. **Chart Rendering**: All charts use simple list mapping, no complex calculations
3. **Memory**: Each `VitalDataModel` ~100 bytes, 120 entries = ~12KB
4. **Scrolling**: Tab content uses `SingleChildScrollView` for smooth vertical scrolling

---

## Common Use Cases

### View Per-Entry Data
1. Tap "Per-Entry View" tab
2. Scroll down to see all 5 metrics individually
3. Each chart shows trend, min/max/avg stats, and current value badge

### Quick Health Summary
1. Tap "Summary" tab
2. See all metrics normalized on 0-100 scale
3. Check SpO2 gauge for oxygen saturation
4. View heart rate distribution across time
5. Analyze blood pressure trends

### Refresh Data
1. Pull down on any tab to trigger refresh
2. `RefreshIndicator` calls `_loadHistory()` to reload from Firebase

### Handle Errors
1. If network error: "Failed To Load History" message + Retry button
2. If no data: "No vitals history available" message + Reload button
3. Tap appropriate button to retry

---

## Future Enhancements

- Add threshold alerts (e.g., SpO2 < 90%)
- Export data to CSV/PDF
- Add date range filtering
- Compare multiple days/weeks
- Add trend analysis (increasing/decreasing)
- Implement caching for offline access
