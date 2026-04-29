# Vitals History Screen — Changes

## Overview

Complete redesign of the vitals history visualization system. Now displays comprehensive vital signs analytics from **vitals/{deviceId}/history** entries only.

## Data Source

- **Single Source**: `vitals/{deviceId}/history` Firebase Realtime Database path
- **Entry Structure**: Each entry contains:
  - `heartRate` (bpm)
  - `spo2` (%)
  - `bodyTemp` (°C)
  - `respiratoryRate` (rpm)
  - `systolicBP` (mmHg)
  - `diastolicBP` (mmHg)
  - `timestamp` (milliseconds since epoch)

## Removed Components

- ❌ All sensor data loading (`getVitalsHistory` combined with `getSensorHistoryFlat`)
- ❌ Sensor seeding logic (`_seedSensorsOnceForDevice`)
- ❌ Flat sensor data conversion (accelerometer, gyroscope, battery, etc.)
- ❌ Old classes: `_VitalsHistorySection`, `_MetricHistoryCard`, `_SensorHistoryCard`
- ❌ SensorModel import and usage
- ❌ `hasDeviceSensorData` checks

## Added Features

### View 1: Per-Entry Charts

Each vital metric displayed with individual readings, trends, and statistics.

**Components**:

1. **Heart Rate Chart** (`_HeartRateChart`)
   - Line chart with fill area (red color)
   - Y-range: min-5 to max+5
   - Stats row: Min, Max, Avg, Readings count

2. **SpO2 Chart** (`_SpO2Chart`)
   - Line chart with fill area (green color)
   - Y-range: 90% to 100% (clinical range)
   - Stats row: Min, Max, Avg, Readings count

3. **Body Temperature Chart** (`_BodyTemperatureChart`)
   - Bar chart, one bar per entry (orange color)
   - Stats row: Min, Max, Avg, Readings count

4. **Respiratory Rate Chart** (`_RespiratoryRateChart`)
   - Line chart, no fill (blue color)
   - Stats row: Min, Max, Avg, Readings count

5. **Blood Pressure Chart** (`_BloodPressureChart`)
   - Dual-line chart:
     - Systolic: solid purple line
     - Diastolic: dashed purple line (dashArray: [5, 5])
   - Stats row: Systolic, Diastolic, Pulse Pressure, Readings count

### View 2: Summary Statistics

Aggregated metrics and distributions across all history entries.

**Components**:

1. **Normalized Metrics Chart** (`_NormalizedMetricsChart`)
   - Horizontal bar chart with 5 bars
   - Metrics: Heart Rate, SpO2, Body Temp, Respiratory Rate, Blood Pressure
   - Normalization formula: `((value - minRef) / (maxRef - minRef)).clamp(0.0, 1.0) * 100`
   - Clinical ranges used:
     - Heart Rate: 40–160 bpm
     - SpO2: 80–100%
     - Body Temp: 35–42°C
     - Respiratory Rate: 8–30 rpm
     - Blood Pressure (systolic): 80–180 mmHg

2. **SpO2 Gauge Chart** (`_SpO2GaugeChart`)
   - Donut-style PieChart showing mean SpO2
   - Center space radius: 55
   - Two sections: mean SpO2 (green), remainder (grey)
   - Center displays percentage value

3. **Heart Rate Histogram** (`_HeartRateHistogram`)
   - Bar chart with 4 buckets:
     - <60 bpm (blue light)
     - 60–80 bpm (blue)
     - 80–100 bpm (orange)
     - > 100 bpm (red)
   - Shows entry count in each range
   - Legend below chart

4. **Blood Pressure Grouped Chart** (`_BloodPressureGroupedChart`)
   - Bar chart with grouped rods (systolic + diastolic side-by-side)
   - One group per entry
   - Systolic: purple[400], Diastolic: purple[200]
   - Legend showing solid vs solid distinction

## Architecture Changes

### File Structure

- **Old**: Single data structure holding both sensors and vitals
- **New**: Only vitals data, eliminated sensor data path entirely

### State Management

- **Tabs**: TabController manages two-view navigation
- **Refresh**: Pull-down gesture refreshes vitals history
- **Error Handling**: Maintains previous error/empty/loading states

### Data Flow

```
1. _SensorsHistory widget receives deviceId
2. _loadHistory() → _fetchVitalsHistory()
3. VitalDataModel.fromMap() parses each entry
4. _HistoryData model holds List<VitalDataModel>
5. Two tab views consume the same vitals list
```

## Styling Consistency

- Card styling: `elevation: 3, BorderRadius.circular(12), Padding(all: 16)`
- Tab styling: Blue background for active tab
- Stat items: 3-column layout (label, value, unit)
- Chart grid: Light grey with appropriate intervals
- Color coding: Red (HR), Green (SpO2), Orange (Temp), Blue (RR), Purple (BP)

## Preserved Functionality

- Error state handling with retry button
- Empty state message with reload button
- RefreshIndicator for manual data refresh
- DatabaseService integration (unchanged)
- AuthService integration (unchanged)
- Loading indicator during data fetch

## Performance

- Single data fetch per history load (120 entries max)
- No repeated sensor seeding or conversion
- Efficient list processing with `.asMap().entries.map()`
- Memory-optimized: vitals only (~12KB per entry vs. 24KB with sensors)

## Testing Checklist

- [ ] Per-entry charts render with correct colors
- [ ] Statistics calculated correctly (Min, Max, Avg)
- [ ] Summary views normalize correctly to 0–100 range
- [ ] Tab switching works smoothly
- [ ] Pull-to-refresh reloads data
- [ ] Error state shows retry button
- [ ] Empty state displays when no history available
- [ ] Device status indicator still visible in AppBar
