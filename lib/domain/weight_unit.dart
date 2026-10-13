/// Unidad con la que se muestra y se captura el peso. El peso siempre se
/// guarda en kilogramos; esto solo convierte en la interfaz.
enum WeightUnit {
  kg('kg', 'Kilogramos'),
  lb('lb', 'Libras');

  const WeightUnit(this.symbol, this.label);
  final String symbol;
  final String label;

  static const double _lbPerKg = 2.2046226218;

  double fromKg(double kg) => this == WeightUnit.kg ? kg : kg * _lbPerKg;
  double toKg(double value) => this == WeightUnit.kg ? value : value / _lbPerKg;

  /// «28.0 kg» / «61.7 lb».
  String format(double kg) => '${fromKg(kg).toStringAsFixed(1)} $symbol';
}
