enum PrivacyStatus { initial, saving, saved, failure }

class PrivacyState {
  final PrivacyStatus status;
  final String userId;
  final bool showRealName;
  final String? errorMessage;

  const PrivacyState({
    this.status = PrivacyStatus.initial,
    this.userId = '',
    this.showRealName = true,
    this.errorMessage,
  });

  PrivacyState copyWith({
    PrivacyStatus? status,
    String? userId,
    bool? showRealName,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return PrivacyState(
      status: status ?? this.status,
      userId: userId ?? this.userId,
      showRealName: showRealName ?? this.showRealName,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
