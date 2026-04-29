import 'package:brew_crew/models/vital_data_model.dart';
import 'package:brew_crew/screens/home/components/latest_vitals_compo/analyse_vitals.dart';
import 'package:brew_crew/screens/home/components/latest_vitals_compo/latest_vitals.dart';
import 'package:flutter/material.dart';

class LatestVitalsAnalysis extends StatelessWidget {
  final VitalDataModel vital;

  const LatestVitalsAnalysis({super.key, required this.vital});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LatestVitals(
            heart: vital.heartRate,
            temperature: vital.bodyTemp,
            spo2: vital.spO2,
            airQuality: vital.respiratoryRate,
          ),
          
          AnalyseVitals(
            heartStatus: vital.heartRateStatus,
            temperatureStatus: vital.bodyTempStatus,
            spo2Status: vital.spO2Status,
            airQualityStatus: vital.respiratoryRateStatus,
            overallStatus: vital.overallStatus,
          ),
        ],
      ),
    );
  }
}
