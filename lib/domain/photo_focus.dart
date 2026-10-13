/// Nuevo enfoque (Alignment -1..1) tras arrastrar la foto [dragPx] píxeles.
/// [overflowPx] es lo que la foto sobresale del marco en ese eje con
/// BoxFit.cover; sin sobrante no hay nada que mover.
/// Arrastrar a la derecha muestra más de la parte izquierda, así que el
/// enfoque se mueve en sentido contrario al dedo.
double nextFocus(double current, double dragPx, double overflowPx) {
  if (overflowPx <= 0) return current;
  return (current - dragPx / (overflowPx / 2)).clamp(-1.0, 1.0);
}
