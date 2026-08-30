class GameAssetManager {
  // Add methods to fetch game specific assets if needed.
  // For example, resolving sound paths, character icons, etc.
  
  String getIconPath(String name) => 'assets/icons/$name.png';
  String getImagePath(String name) => 'assets/images/$name.png';
  String getAudioPath(String name) => 'assets/audio/$name.mp3';
}
