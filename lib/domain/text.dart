/// Clave para comparar nombres de producto: sin mayúsculas ni espacios de más.
String normalizeName(String s) =>
    s.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

const _from = 'áàäâéèëêíìïîóòöôúùüûñÁÀÄÂÉÈËÊÍÌÏÎÓÒÖÔÚÙÜÛÑ';
const _to = 'aaaaeeeeiiiioooouuuunAAAAEEEEIIIIOOOOUUUUN';

/// Minúsculas y sin acentos, para búsquedas.
String foldText(String s) {
  final b = StringBuffer();
  for (final ch in s.split('')) {
    final i = _from.indexOf(ch);
    b.write(i >= 0 ? _to[i] : ch);
  }
  return b.toString().toLowerCase();
}
