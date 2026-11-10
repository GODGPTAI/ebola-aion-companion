class EbolaEntitlementPolicy {
  /// Separate purchased-device entitlement from optional AI usage plans.
  final bool activePhysicalDevice;
  final bool aiSubscriptionActive;
  const EbolaEntitlementPolicy({required this.activePhysicalDevice,required this.aiSubscriptionActive});
  bool get canUseDeviceControl => activePhysicalDevice;
  bool get canUsePaidAi => activePhysicalDevice && aiSubscriptionActive;
}
