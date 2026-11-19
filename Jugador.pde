class Jugador {
  float x, y; float velX, velY; float yAnterior; int vida = 100; color c;
  int teclaIzq, teclaDer, teclaSalto, teclaAbajo, teclaDisparo, teclaAgarrar;
  float gravedad = 0.6; float fuerzaSalto = -12;
  boolean enElPiso = false; int saltosRestantes = 2; boolean puedeSaltar = true; 
  int tiempoUltimoAbajo = 0; boolean teclaAbajoAnterior = false; boolean atravesandoPlataforma = false; 
  
  int armaEquipada = 0; // 0: Puños, 1: Pistola, 2: Metralleta, 3: Escopeta
  int tiempoInicioArma = 0;
  int duracionArma = 8000; 
  
  boolean teclaAgarrarAnterior = false; 
  boolean teclaDisparoAnterior = false; 
  
  int tiempoUltimoAtaque = 0;
  int cadencia = 300; 
  int direccionMirada = 1; 

  Jugador(float startX, float startY, color miColor, int izq, int der, int salto, int abajo, int disparo, int agarrar) {
    x = startX; y = startY; c = miColor;
    teclaIzq = izq; teclaDer = der; teclaSalto = salto;
    teclaAbajo = abajo; teclaDisparo = disparo; teclaAgarrar = agarrar;
  }

  void actualizar() {
    yAnterior = y;
    
    if (teclas[teclaIzq]) { velX -= 1.5; direccionMirada = -1; }
    if (teclas[teclaDer]) { velX += 1.5; direccionMirada = 1; }
    velX *= 0.8; 
    
    if (!teclas[teclaSalto]) puedeSaltar = true; 
    if (teclas[teclaSalto] && puedeSaltar && saltosRestantes > 0) {
      velY = fuerzaSalto; saltosRestantes--; puedeSaltar = false; enElPiso = false; atravesandoPlataforma = false; 
    }
    
    boolean apretandoAbajo = teclas[teclaAbajo];
    if (apretandoAbajo && !teclaAbajoAnterior) {
      if (millis() - tiempoUltimoAbajo < 250) { atravesandoPlataforma = true; velY = 12; enElPiso = false; }
      tiempoUltimoAbajo = millis(); 
    }
    teclaAbajoAnterior = apretandoAbajo; 
    
    boolean apretandoAgarrar = teclas[teclaAgarrar];
    if (apretandoAgarrar && !teclaAgarrarAnterior) {
      intentarAgarrarOSoltar();
    }
    teclaAgarrarAnterior = apretandoAgarrar;
    
    if (armaEquipada != 0) { 
      if (millis() - tiempoInicioArma > duracionArma) armaEquipada = 0; 
    }
    
    boolean apretandoDisparo = teclas[teclaDisparo];
    
    if (vida > 0) {
      if (armaEquipada == 0 || armaEquipada == 1 || armaEquipada == 3) {
        if (apretandoDisparo && !teclaDisparoAnterior && millis() - tiempoUltimoAtaque > cadencia) {
          if (armaEquipada == 0) pegarPina(); else disparar();
          tiempoUltimoAtaque = millis();
        }
      } else if (armaEquipada == 2) {
        if (apretandoDisparo && millis() - tiempoUltimoAtaque > cadencia) {
          disparar(); tiempoUltimoAtaque = millis();
        }
      }
    }
    teclaDisparoAnterior = apretandoDisparo;

    velY += gravedad; x += velX; y += velY; enElPiso = false; 

    if (y > ALTO - 50 - 25) { 
      y = ALTO - 50 - 25; velY = 0; enElPiso = true; saltosRestantes = 2; atravesandoPlataforma = false; 
    }
    if (velY >= 0 && !atravesandoPlataforma) { 
      if (x > 300 - 25 && x < 700 + 25) { 
        if (yAnterior + 25 <= 400 && y + 25 >= 400) { y = 400 - 25; velY = 0; enElPiso = true; saltosRestantes = 2; }
      }
    }
    if (x < 25) x = 25; if (x > ANCHO - 25) x = ANCHO - 25;
  }
  
  void intentarAgarrarOSoltar() {
    if (armaEquipada != 0) {
      armasEnPiso.add(new ArmaItem(x, y, armaEquipada)); armaEquipada = 0;
    } else {
      for (int i = 0; i < armasEnPiso.size(); i++) {
        ArmaItem arma = armasEnPiso.get(i);
        if (dist(x, y, arma.x, arma.y) < 40) {
          armaEquipada = arma.tipo;
          tiempoInicioArma = millis(); 
          if (armaEquipada == 1) cadencia = 0;    
          if (armaEquipada == 2) cadencia = 80;   
          if (armaEquipada == 3) cadencia = 800;  
          armasEnPiso.remove(i); break; 
        }
      }
    }
  }
  
  void pegarPina() {
    Jugador enemigo = (this == j1) ? j2 : j1;
    if (dist(x, y, enemigo.x, enemigo.y) < 60) {
      if ((direccionMirada == 1 && enemigo.x > x) || (direccionMirada == -1 && enemigo.x < x)) {
        enemigo.recibirDano(5, 10 * direccionMirada); 
      }
    }
  }

  void disparar() {
    if (armaEquipada == 1 || armaEquipada == 2) balas.add(new Bala(x, y, direccionMirada * 25, 0, c, this));
    else if (armaEquipada == 3) {
      balas.add(new Bala(x, y, direccionMirada * 25, -4, c, this)); balas.add(new Bala(x, y, direccionMirada * 25, -1, c, this)); 
      balas.add(new Bala(x, y, direccionMirada * 25, 1, c, this));  balas.add(new Bala(x, y, direccionMirada * 25, 4, c, this));  
      velX -= 15 * direccionMirada; 
    }
  }

  void recibirDano(int cantidad, float fuerzaEmpuje) { vida -= cantidad; velX += fuerzaEmpuje; }

  void mostrar() {
    if (vida <= 0) return; 
    fill(c); noStroke(); ellipse(x, y, 50, 50);
    
    if (armaEquipada != 0) {
      float tRestante = duracionArma - (millis() - tiempoInicioArma);
      float anchoBarra = map(tRestante, 0, duracionArma, 0, 40);
      fill(255); rectMode(CENTER); rect(x, y - 40, anchoBarra, 4);
    }
    
    if (armaEquipada == 1) { stroke(150); strokeWeight(5); line(x, y, x + (25 * direccionMirada), y); } 
    else if (armaEquipada == 2) { stroke(139, 69, 19); strokeWeight(6); line(x, y, x + (40 * direccionMirada), y); stroke(100); strokeWeight(4); line(x + (15 * direccionMirada), y, x + (40 * direccionMirada), y); } 
    else if (armaEquipada == 3) { stroke(50); strokeWeight(8); line(x, y, x + (35 * direccionMirada), y); }
    else { fill(255); noStroke(); ellipse(x + (25 * direccionMirada), y, 15, 15); }
  }
}
