import 'dart:async';
import 'package:dragon_center_linux/models/msi_config.dart';
import 'package:dragon_center_linux/shared/services/config_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dragon_center_linux/features/fan_control/models/fan_curve.dart';
import 'package:dragon_center_linux/core/utils/logger.dart';

class FanConfig {
  static final ConfigManager _configManager = ConfigManager();
  static int profile = 1;
  static List<List<int>> autoSpeed = [];
  static List<List<int>> advancedSpeed = [];
  static int basicOffset = 0;
  static int cpuGen = 1; // Set to 1 for 10th gen
  static List<int> autoAdvancedValues = [];
  static List<int> coolerBoosterValues = [];
  static List<List<int>> fanAddresses = [];
  static List<int> tempAddresses = [];
  static List<int> rpmAddresses = [];
  static int batteryThreshold = 100;

  static FanCurve cpuFanCurve = FanCurve.defaults();
  static FanCurve gpuFanCurve = FanCurve.gpuDefaults();

  static Future<void> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      await _configManager.detectModel();

      // Load selected model or fallback to detected
      String? savedModel = prefs.getString('selected_model');
      if (savedModel != null) {
        MSIConfig.currentModel = savedModel;
      } else {
        // Try to use detected model if available in config
        try {
          String detectedModel = _configManager.currentConfig.modelCode;
          if (MSIConfig.availableModels.contains(detectedModel)) {
            MSIConfig.currentModel = detectedModel;
          }
        } catch (_) {
          // Ignore if no model detected
        }
      }

      final config = _configManager.currentConfig;

      profile = _safeParseInt(prefs.getInt('profile'), config.defaultProfile);
      batteryThreshold = _safeParseInt(
          prefs.getInt('batteryThreshold'), config.defaultBatteryThreshold);
      basicOffset =
          _safeParseInt(prefs.getInt('basicOffset'), config.defaultBasicOffset);

      cpuGen = 1;

      autoSpeed = _parseNestedList(prefs.getString('autoSpeed')) ??
          [MSIConfig.cpuFanSpeeds, MSIConfig.gpuFanSpeeds];
      advancedSpeed = _parseNestedList(prefs.getString('advSpeed')) ??
          [MSIConfig.cpuFanSpeeds, MSIConfig.gpuFanSpeeds];

      // Auto mode (12) is hardcoded for now as it's consistent across models
      autoAdvancedValues = [MSIConfig.fanModeAddress, 12, MSIConfig.fanMode];

      coolerBoosterValues = [
        MSIConfig.coolerBoostAddress,
        MSIConfig.coolerBoostOff,
        MSIConfig.coolerBoostOn
      ];

      fanAddresses = [
        MSIConfig.cpuFanSpeedAddresses,
        MSIConfig.gpuFanSpeedAddresses
      ];
      tempAddresses = [
        MSIConfig.realtimeCpuTempAddress,
        MSIConfig.realtimeGpuTempAddress
      ];
      rpmAddresses = [
        MSIConfig.realtimeCpuFanRpmAddress,
        MSIConfig.realtimeGpuFanRpmAddress
      ];

      try {
        final cpuCurveStr = prefs.getString('cpuFanCurve');
        final gpuCurveStr = prefs.getString('gpuFanCurve');

        if (cpuCurveStr != null && gpuCurveStr != null) {
          cpuFanCurve = FanCurve.fromStorageString(cpuCurveStr);
          gpuFanCurve = FanCurve.fromStorageString(gpuCurveStr);

          for (var speed in cpuFanCurve.fanSpeeds) {
            if (speed < 0 || speed > config.maxFanSpeed) {
              throw Exception('Invalid CPU fan speed: $speed');
            }
          }
          for (var speed in gpuFanCurve.fanSpeeds) {
            if (speed < 0 || speed > config.maxFanSpeed) {
              throw Exception('Invalid GPU fan speed: $speed');
            }
          }
        } else {
          cpuFanCurve = FanCurve.defaults();
          gpuFanCurve = FanCurve.gpuDefaults();
        }
      } catch (e) {
        cpuFanCurve = FanCurve.defaults();
        gpuFanCurve = FanCurve.gpuDefaults();
        logger.warning('Failed to load fan curves, using defaults: $e');
      }
    } catch (e) {
      logger.severe('Failed to load config: $e');
      _resetToDefaults();
      await saveConfig();
    }
  }

  static int _safeParseInt(int? value, int defaultValue) {
    return value ?? defaultValue;
  }

  static List<List<int>>? _parseNestedList(String? value) {
    try {
      if (value == null) return null;
      return value
          .split(';')
          .map((e) => e.split(',').map((s) => int.tryParse(s) ?? 0).toList())
          .toList();
    } catch (e) {
      return null;
    }
  }

  static void _resetToDefaults() {
    final config = _configManager.currentConfig;
    profile = config.defaultProfile;
    batteryThreshold = config.defaultBatteryThreshold;
    basicOffset = config.defaultBasicOffset;
    cpuGen = 1; // Set to 1 for 10th gen
    autoSpeed = [MSIConfig.cpuFanSpeeds, MSIConfig.gpuFanSpeeds];
    advancedSpeed = [MSIConfig.cpuFanSpeeds, MSIConfig.gpuFanSpeeds];

    autoAdvancedValues = [MSIConfig.fanModeAddress, 12, MSIConfig.fanMode];
    coolerBoosterValues = [
      MSIConfig.coolerBoostAddress,
      MSIConfig.coolerBoostOff,
      MSIConfig.coolerBoostOn
    ];

    fanAddresses = [
      MSIConfig.cpuFanSpeedAddresses,
      MSIConfig.gpuFanSpeedAddresses
    ];
    tempAddresses = [
      MSIConfig.realtimeCpuTempAddress,
      MSIConfig.realtimeGpuTempAddress
    ];
    rpmAddresses = [
      MSIConfig.realtimeCpuFanRpmAddress,
      MSIConfig.realtimeGpuFanRpmAddress
    ];

    cpuFanCurve = FanCurve.defaults();
    gpuFanCurve = FanCurve.gpuDefaults();
  }

  static Future<void> saveConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('profile', profile);
    await prefs.setInt('batteryThreshold', batteryThreshold);
    await prefs.setInt('basicOffset', basicOffset);
    await prefs.setInt('cpuGen', cpuGen);

    await prefs.setString('autoSpeed', _serializeNestedList(autoSpeed));
    await prefs.setString('advSpeed', _serializeNestedList(advancedSpeed));

    await prefs.setString('autoAdvValues', autoAdvancedValues.join(','));
    await prefs.setString('coolerBoosterValues', coolerBoosterValues.join(','));

    await prefs.setString('cpuFanCurve', cpuFanCurve.toStorageString());
    await prefs.setString('gpuFanCurve', gpuFanCurve.toStorageString());
  }

  static String _serializeNestedList(List<List<int>> list) {
    return list.map((e) => e.join(',')).join(';');
  }
}
