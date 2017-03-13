if (Notification && Notification.permission !== 'granted' && Notification.permission !== 'denied') {
    Notification.requestPermission();
}
