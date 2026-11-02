class SpokenLine {
  const SpokenLine(this.text, {this.clip, this.beats = const []});

  final String text;
  final String? clip;
  final List<double> beats;
}
