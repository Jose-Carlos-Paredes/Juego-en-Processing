class Bala {
  float x, y;
  float velX, velY; 
  color c;
  Jugador tirador; 
  
  Bala(float startX, float startY, float vX, float vY, color miColor, Jugador dueño) {
    x = startX;
    y = startY;
    velX = vX;
    velY = vY; 
    c = miColor;
    tirador = dueño;
  }
  
  void mover() {
    x += velX;
    y += velY; 
  }
  
  void mostrar() {
    fill(255, 255, 0); 
    noStroke();
    rectMode(CENTER);
    rect(x, y, 10, 10);
  }
}
