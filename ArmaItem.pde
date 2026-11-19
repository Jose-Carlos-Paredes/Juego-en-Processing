class ArmaItem {
  float x, y; float velY; float gravedad = 0.6;
  int tipo; // 1: Pistola, 2: Metralleta, 3: Escopeta

  ArmaItem(float startX, float startY, int tipoArma) {
    x = startX; y = startY; velY = 0; tipo = tipoArma; 
  }

  void actualizar() {
    float yAnterior = y; velY += gravedad; y += velY;

    if (y > ALTO - 50 - 10) { y = ALTO - 50 - 10; velY = 0; }
    if (velY >= 0) {
      if (x > 300 - 10 && x < 700 + 10) {
        if (yAnterior + 10 <= 400 && y + 10 >= 400) { y = 400 - 10; velY = 0; }
      }
    }
  }

  void mostrar() {
    rectMode(CENTER);
    if (tipo == 1) fill(0, 255, 0);       
    else if (tipo == 2) fill(255, 150, 0); 
    else if (tipo == 3) fill(255, 0, 0);   
    
    stroke(255); strokeWeight(2); rect(x, y, 30, 15);
    fill(100); noStroke();
    rect(x + 5, y - 2, 10, 4); rect(x - 5, y + 2, 4, 8);
  }
}
