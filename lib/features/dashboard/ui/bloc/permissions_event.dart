abstract class PermissionsEvent {}

class PermissionsStarted extends PermissionsEvent {}

class PermissionsRefreshed extends PermissionsEvent {}

class CameraPermissionTapped extends PermissionsEvent {}

class LocationPermissionTapped extends PermissionsEvent {}
