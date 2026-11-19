import processing.net.*;
import java.net.*;

// ==========================================
// RESOLUCIÓN INTERNA PARA PANTALLA COMPLETA
// ==========================================
final float ANCHO = 1000;
final float ALTO = 600;

// ==========================================
// VARIABLES DE RED (SERVIDOR / CLIENTE)
// ==========================================
Server s = null;
Client c = null;

boolean modoOnline = false;
boolean esServidor = false;
boolean clienteConectado = false;
boolean running = true;

String serverIP = "";
String ipManual = ""; // IP que escribís a mano en la PC 2
String miIP = "Buscando IP...";
String estadoConexion = "Escribí la IP del Servidor o usá búsqueda automática";

boolean[] teclasCliente = new boolean[6]; // 0:Izq, 1:Der, 2:Salto, 3:Abajo, 4:Disparo, 5:Agarrar
String ultimoEstadoRecibido = "";
final Object lockRed = new Object();

// ==========================================
// VARIABLES DEL JUEGO
// ==========================================
boolean[] teclas = new boolean[256];
PFont fuenteJuego;

// 0: Menú, 1: Jugando, 2: Fin del juego, 3: Conectar, 4: Gestionar Servidor
int estadoJuego = 0; 
String textoGanador = "";

Jugador j1;
Jugador j2;
ArrayList<Bala> balas;
ArrayList<ArmaItem> armasEnPiso; 

int temporizadorArmas = 0;
int tiempoProximaArma = 7000; 

void setup() {
  fullScreen();
  
  fuenteJuego = createFont("Impact", 60);
  textFont(fuenteJuego);
  
  try {
    miIP = InetAddress.getLocalHost().getHostAddress();
  } catch (Exception e) {
    miIP = "No disponible";
  }
  
  reiniciarPartida();
  estadoJuego = 0; 
}

void draw() {
  scale(width / ANCHO, height / ALTO);
  background(30);
  
  if (estadoJuego == 0) dibujarMenu();
  else if (estadoJuego == 1) jugarPartida();
  else if (estadoJuego == 2) dibujarPantallaFin();
  else if (estadoJuego == 3) dibujarPantallaConectar();
  else if (estadoJuego == 4) dibujarPantallaServidor();
}

// ==========================================
// PANTALLAS DEL MENÚ Y RED
// ==========================================
void dibujarMenu() {
  textoMulticolor("ARENA FIGHT", ANCHO/2, 120, 72);
  
  fill(200);
  textAlign(CENTER, CENTER);
  textSize(20);
  text("SELECCIONÁ UNA OPCIÓN PARA COMENZAR", ANCHO/2, 185);
  
  dibujarBoton("JUGAR", ANCHO/2, 265, 330, 65);
  dibujarBoton("CONECTAR", ANCHO/2, 355, 330, 65);
  dibujarBoton("GESTIONAR SERVIDOR", ANCHO/2, 445, 330, 65);
}

void dibujarPantallaConectar() {
  textoMulticolor("CONECTAR A SERVIDOR", ANCHO/2, 100, 52);
  
  textAlign(CENTER, CENTER);
  fill(220);
  textSize(20);
  text(estadoConexion, ANCHO/2, 165);
  
  // Caja de texto para escribir la IP manualmente
  rectMode(CENTER);
  fill(20);
  stroke(255);
  strokeWeight(2);
  rect(ANCHO/2, 235, 360, 50, 10);
  
  fill(255, 220, 0);
  textSize(28);
  String cursor = (frameCount / 25) % 2 == 0 ? "_" : "";
  text(ipManual.length() > 0 ? ipManual + cursor : "Ej: 192.168.0.15", ANCHO/2, 235);
  
  dibujarBoton("CONECTAR POR IP", ANCHO/2, 325, 310, 58);
  dibujarBoton("BUSCAR AUTO (UDP)", ANCHO/2, 400, 310, 58);
  dibujarBoton("VOLVER", ANCHO/2, 490, 220, 58);
}

void dibujarPantallaServidor() {
  textoMulticolor("GESTIONAR SERVIDOR", ANCHO/2, 140, 52);
  
  textAlign(CENTER, CENTER);
  fill(255, 220, 0);
  textSize(34);
  text("TU IP LOCAL: " + miIP, ANCHO/2, 240);
  
  fill(220);
  textSize(22);
  text("Esperando a que el Jugador 2 se conecte...", ANCHO/2, 305);
  fill(150);
  textSize(18);
  text("Pasale esa IP a la otra compu (puerto 12345)", ANCHO/2, 345);
  
  dibujarBoton("VOLVER", ANCHO/2, 460, 240, 65);
}

// ==========================================
// LETRAS MULTICOLOR Y BOTONES REDONDOS
// ==========================================
void textoMulticolor(String texto, float x, float y, float tamano) {
  textSize(tamano);
  float anchoTotal = textWidth(texto);
  float xActual = x - anchoTotal / 2;
  float sombra = tamano * 0.06;
  
  textAlign(LEFT, CENTER);
  for (int i = 0; i < texto.length(); i++) {
    char letra = texto.charAt(i);
    colorMode(RGB, 255);
    fill(0);
    text(letra, xActual + sombra, y + sombra);
    
    colorMode(HSB, 360, 100, 100);
    float tono = (i * 35 + frameCount * 3) % 360;
    fill(tono, 90, 100);
    text(letra, xActual, y);
    xActual += textWidth(letra);
  }
  colorMode(RGB, 255);
  textAlign(CENTER, CENTER);
}

void dibujarBoton(String texto, float x, float y, float w, float h) {
  ellipseMode(CENTER);
  stroke(255);
  strokeWeight(3);
  if (mouseSobreBoton(x, y, w, h)) fill(70, 70, 90);
  else fill(45);
  ellipse(x, y, w, h);
  textoMulticolor(texto, x, y, 24);
}

boolean mouseSobreBoton(float x, float y, float w, float h) {
  float mx = mouseX * (ANCHO / width);
  float my = mouseY * (ALTO / height);
  float rx = w / 2.0;
  float ry = h / 2.0;
  return (sq(mx - x) / sq(rx) + sq(my - y) / sq(ry)) <= 1;
}

void mousePressed() {
  if (estadoJuego == 0) {
    if (mouseSobreBoton(ANCHO/2, 265, 330, 65)) {
      modoOnline = false;
      reiniciarPartida();
    }
    else if (mouseSobreBoton(ANCHO/2, 355, 330, 65)) {
      estadoJuego = 3;
      estadoConexion = "Escribí la IP del Servidor o usá búsqueda automática";
    }
    else if (mouseSobreBoton(ANCHO/2, 445, 330, 65)) {
      estadoJuego = 4;
      iniciarServidor();
    }
  } 
  else if (estadoJuego == 3) {
    if (mouseSobreBoton(ANCHO/2, 325, 310, 58)) {
      estadoConexion = "Conectando a " + ipManual + "...";
      thread("conectarManual");
    }
    else if (mouseSobreBoton(ANCHO/2, 400, 310, 58)) {
      estadoConexion = "Buscando servidor en la red local (UDP)...";
      thread("conectarAlServidor");
    }
    else if (mouseSobreBoton(ANCHO/2, 490, 220, 58)) {
      estadoJuego = 0;
    }
  }
  else if (estadoJuego == 4) {
    if (mouseSobreBoton(ANCHO/2, 460, 240, 65)) {
      estadoJuego = 0;
    }
  }
}

// ==========================================
// LÓGICA DE RED (SERVIDOR, CLIENTE Y UDP)
// ==========================================
void iniciarServidor() {
  if (s == null) {
    modoOnline = true;
    esServidor = true;
    clienteConectado = false;
    s = new Server(this, 12345);
    println("Modo: SERVIDOR iniciado en puerto 12345.");
    thread("responderDescubrimiento");
    thread("recibirDatos");
  }
}

void serverEvent(Server someServer, Client someClient) {
  println("¡Jugador 2 conectado desde: " + someClient.ip() + "!");
  clienteConectado = true;
  reiniciarPartida();
}

void conectarManual() {
  String ip = ipManual.trim();
  if (ip.length() == 0) {
    estadoConexion = "Primero escribí la IP de la PC 1.";
    return;
  }
  conectarPorTCP(ip);
}

void conectarAlServidor() {
  serverIP = buscarServidorEnRed();
  if (serverIP == null) {
    estadoConexion = "No se encontró automático. Probá escribir la IP a mano.";
    return;
  }
  conectarPorTCP(serverIP);
}

void conectarPorTCP(String ipDestino) {
  try {
    c = new Client(this, ipDestino, 12345);
    if (c.active()) {
      modoOnline = true;
      esServidor = false;
      println("Modo: CLIENTE. Conectado a: " + ipDestino);
      reiniciarPartida();
      thread("recibirDatos");
    } else {
      estadoConexion = "No respondió " + ipDestino + ". Revisá el Firewall o la IP.";
    }
  } catch (Exception e) {
    estadoConexion = "Error al conectar con " + ipDestino;
  }
}

void recibirDatos() {
  while (running) {
    if (esServidor && s != null) {
      Client incoming = s.available();
      if (incoming != null) {
        String input = incoming.readStringUntil('\n');
        if (input != null) {
          input = input.trim();
          if (input.startsWith("IN,")) {
            String[] p = split(input, ',');
            if (p.length == 7) {
              synchronized(lockRed) {
                for (int i = 0; i < 6; i++) {
                  teclasCliente[i] = p[i + 1].equals("1");
                }
              }
            }
          }
        }
      }
    } 
    else if (!esServidor && c != null && c.available() > 0) {
      String input = c.readStringUntil('\n');
      if (input != null) {
        input = input.trim();
        if (input.startsWith("ST|")) {
          synchronized(lockRed) {
            ultimoEstadoRecibido = input;
          }
        }
      }
    }
    try { Thread.sleep(5); } catch (Exception e) {}
  }
}

String buscarServidorEnRed() {
  try {
    DatagramSocket socket = new DatagramSocket();
    socket.setBroadcast(true);
    byte[] mensaje = "HAY_SERVER?".getBytes();
    DatagramPacket paqueteEnvio = new DatagramPacket(mensaje, mensaje.length, InetAddress.getByName("255.255.255.255"), 8888);
    socket.send(paqueteEnvio);
    
    socket.setSoTimeout(1500);
    byte[] bufferRecepcion = new byte[1024];
    DatagramPacket paqueteRespuesta = new DatagramPacket(bufferRecepcion, bufferRecepcion.length);
    socket.receive(paqueteRespuesta);
    
    String ipDescubierta = paqueteRespuesta.getAddress().getHostAddress();
    socket.close();
    return ipDescubierta;
  } catch (Exception e) {
    return null;
  }
}

void responderDescubrimiento() {
  try {
    DatagramSocket serverSocket = new DatagramSocket(8888);
    byte[] bufferRecepcion = new byte[1024];
    while (running) {
      DatagramPacket paqueteEntrante = new DatagramPacket(bufferRecepcion, bufferRecepcion.length);
      serverSocket.receive(paqueteEntrante);
      String mensaje = new String(paqueteEntrante.getData(), 0, paqueteEntrante.getLength());
      if (mensaje.equals("HAY_SERVER?")) {
        byte[] respuesta = "ESTOY".getBytes();
        DatagramPacket paqueteRespuesta = new DatagramPacket(respuesta, respuesta.length, paqueteEntrante.getAddress(), paqueteEntrante.getPort());
        serverSocket.send(paqueteRespuesta);
      }
    }
  } catch (Exception e) {
    println("Aviso UDP: " + e.getMessage());
  }
}

// ==========================================
// SINCRONIZACIÓN DE ESTADO (PROTOCOLO TCP)
// ==========================================
void enviarInputsCliente() {
  if (c == null) return;
  int izq = (teclas['a'] || teclas['A'] || teclas[LEFT]) ? 1 : 0;
  int der = (teclas['d'] || teclas['D'] || teclas[RIGHT]) ? 1 : 0;
  int sal = (teclas['w'] || teclas['W'] || teclas[UP]) ? 1 : 0;
  int aba = (teclas['s'] || teclas['S'] || teclas[DOWN]) ? 1 : 0;
  int dis = (teclas['g'] || teclas['G'] || teclas['ñ'] || teclas['Ñ']) ? 1 : 0;
  int aga = (teclas['f'] || teclas['F'] || teclas['l'] || teclas['L']) ? 1 : 0;
  
  c.write("IN," + izq + "," + der + "," + sal + "," + aba + "," + dis + "," + aga + "\n");
}

void enviarEstadoJuego() {
  if (s == null) return;
  int tRest1 = (j1.armaEquipada != 0) ? max(0, j1.duracionArma - (millis() - j1.tiempoInicioArma)) : 0;
  int tRest2 = (j2.armaEquipada != 0) ? max(0, j2.duracionArma - (millis() - j2.tiempoInicioArma)) : 0;
  
  StringBuilder sb = new StringBuilder();
  sb.append("ST|").append(estadoJuego).append("|");
  sb.append(int(j1.x)).append(",").append(int(j1.y)).append(",").append(j1.vida).append(",").append(j1.armaEquipada).append(",").append(j1.direccionMirada).append(",").append(tRest1).append("|");
  sb.append(int(j2.x)).append(",").append(int(j2.y)).append(",").append(j2.vida).append(",").append(j2.armaEquipada).append(",").append(j2.direccionMirada).append(",").append(tRest2).append("|");
  
  if (balas.size() == 0) {
    sb.append("NONE");
  } else {
    for (int i = 0; i < balas.size(); i++) {
      Bala b = balas.get(i);
      if (i > 0) sb.append(";");
      sb.append(int(b.x)).append(",").append(int(b.y));
    }
  }
  sb.append("|");
  
  if (armasEnPiso.size() == 0) {
    sb.append("NONE");
  } else {
    for (int i = 0; i < armasEnPiso.size(); i++) {
      ArmaItem a = armasEnPiso.get(i);
      if (i > 0) sb.append(";");
      sb.append(int(a.x)).append(",").append(int(a.y)).append(",").append(a.tipo);
    }
  }
  sb.append("\n");
  s.write(sb.toString());
}

void aplicarEstadoCliente() {
  String estado;
  synchronized(lockRed) {
    estado = ultimoEstadoRecibido;
  }
  if (estado == null || estado.length() == 0) return;
  
  String[] partes = split(estado, '|');
  if (partes.length < 6) return;
  
  estadoJuego = int(partes[1]);
  
  String[] d1 = split(partes[2], ',');
  if (d1.length == 6) {
    j1.x = float(d1[0]); j1.y = float(d1[1]); j1.vida = int(d1[2]);
    j1.armaEquipada = int(d1[3]); j1.direccionMirada = int(d1[4]);
    j1.tiempoInicioArma = millis() - (j1.duracionArma - int(d1[5]));
  }
  
  String[] d2 = split(partes[3], ',');
  if (d2.length == 6) {
    j2.x = float(d2[0]); j2.y = float(d2[1]); j2.vida = int(d2[2]);
    j2.armaEquipada = int(d2[3]); j2.direccionMirada = int(d2[4]);
    j2.tiempoInicioArma = millis() - (j2.duracionArma - int(d2[5]));
  }
  
  balas.clear();
  if (!partes[4].equals("NONE")) {
    String[] listaB = split(partes[4], ';');
    for (String item : listaB) {
      String[] xy = split(item, ',');
      if (xy.length == 2) balas.add(new Bala(float(xy[0]), float(xy[1]), 0, 0, color(255), null));
    }
  }
  
  armasEnPiso.clear();
  if (!partes[5].equals("NONE")) {
    String[] listaA = split(partes[5], ';');
    for (String item : listaA) {
      String[] xyt = split(item, ',');
      if (xyt.length == 3) armasEnPiso.add(new ArmaItem(float(xyt[0]), float(xyt[1]), int(xyt[2])));
    }
  }
  
  if (j1.vida <= 0) textoGanador = "¡JUGADOR 2 (AZUL) GANA!";
  else if (j2.vida <= 0) textoGanador = "¡JUGADOR 1 (ROJO) GANA!";
}

// ==========================================
// BUCLE DEL JUEGO (ESTADO 1 Y 2)
// ==========================================
void jugarPartida() {
  dibujarPlataformas();
  
  if (modoOnline && !esServidor) {
    enviarInputsCliente();
    aplicarEstadoCliente();
    
    for (ArmaItem arma : armasEnPiso) arma.mostrar();
    for (Bala b : balas) b.mostrar();
    j1.mostrar();
    j2.mostrar();
    dibujarUI();
    return;
  }
  
  if (modoOnline && esServidor) {
    synchronized(lockRed) {
      teclas[LEFT]  = teclasCliente[0];
      teclas[RIGHT] = teclasCliente[1];
      teclas[UP]    = teclasCliente[2];
      teclas[DOWN]  = teclasCliente[3];
      teclas['ñ']   = teclasCliente[4];
      teclas['l']   = teclasCliente[5];
    }
  }
  
  if (millis() - temporizadorArmas > tiempoProximaArma) {
    int tipoRandom = int(random(1, 4)); 
    armasEnPiso.add(new ArmaItem(random(100, 900), -50, tipoRandom));
    temporizadorArmas = millis();
    tiempoProximaArma = int(random(7000, 12000)); 
  }
  
  for (int i = armasEnPiso.size() - 1; i >= 0; i--) {
    ArmaItem arma = armasEnPiso.get(i);
    arma.actualizar();
    arma.mostrar();
  }
  
  for (int i = balas.size() - 1; i >= 0; i--) {
    Bala b = balas.get(i);
    b.mover();
    b.mostrar();
    
    boolean destruida = false;
    if (b.tirador != j1 && dist(b.x, b.y, j1.x, j1.y) < 25) {
      j1.recibirDano(10, b.velX); destruida = true;
    }
    if (!destruida && b.tirador != j2 && dist(b.x, b.y, j2.x, j2.y) < 25) {
      j2.recibirDano(10, b.velX); destruida = true;
    }
    if (destruida || b.x < 0 || b.x > ANCHO || b.y < 0 || b.y > ALTO) balas.remove(i);
  }
  
  j1.actualizar();
  j2.actualizar();
  evitarTraspasoJugadores();
  
  j1.mostrar();
  j2.mostrar();
  dibujarUI();
  
  if (j1.vida <= 0) {
    estadoJuego = 2; textoGanador = "¡JUGADOR 2 (AZUL) GANA!";
  } else if (j2.vida <= 0) {
    estadoJuego = 2; textoGanador = "¡JUGADOR 1 (ROJO) GANA!";
  }
  
  if (modoOnline && esServidor) {
    enviarEstadoJuego();
  }
}

void dibujarPantallaFin() {
  if (modoOnline && esServidor) enviarEstadoJuego();
  if (modoOnline && !esServidor) aplicarEstadoCliente();
  
  dibujarPlataformas();
  j1.mostrar(); 
  j2.mostrar(); 
  dibujarUI();
  
  rectMode(CORNER);
  fill(0, 200); 
  rect(0, 0, ANCHO, ALTO);
  
  textoMulticolor(textoGanador, ANCHO/2, ALTO/2 - 50, 56);
  
  textAlign(CENTER, CENTER);
  fill(255); 
  textSize(24);
  if (!modoOnline || esServidor) {
    text("PRESIONÁ 'R' PARA JUGAR LA REVANCHA", ANCHO/2, ALTO/2 + 30);
    if (teclas['r'] || teclas['R']) reiniciarPartida();
  } else {
    text("ESPERANDO QUE EL SERVIDOR REINICIE...", ANCHO/2, ALTO/2 + 30);
  }
  text("PRESIONÁ 'M' PARA VOLVER AL MENÚ", ANCHO/2, ALTO/2 + 70);
  
  if (teclas['m'] || teclas['M']) estadoJuego = 0;
}

void reiniciarPartida() {
  balas = new ArrayList<Bala>();
  armasEnPiso = new ArrayList<ArmaItem>();
  estadoJuego = 1; 
  temporizadorArmas = millis();
  tiempoProximaArma = int(random(3000, 6000)); 
  
  j1 = new Jugador(200, 100, color(255, 50, 50), 'a', 'd', 'w', 's', 'g', 'f'); 
  j2 = new Jugador(800, 100, color(50, 100, 255), LEFT, RIGHT, UP, DOWN, 'ñ', 'l');
}

void evitarTraspasoJugadores() {
  float distancia = dist(j1.x, j1.y, j2.x, j2.y);
  if (distancia < 50) {
    float overlap = 50 - distancia; 
    if (j1.x < j2.x) { j1.x -= overlap / 2; j2.x += overlap / 2; } 
    else { j1.x += overlap / 2; j2.x -= overlap / 2; }
  }
}

void keyPressed() {
  // Escritura de IP en la pantalla de Conectar
  if (estadoJuego == 3) {
    if ((key >= '0' && key <= '9') || key == '.') {
      if (ipManual.length() < 15) ipManual += key;
    } else if (key == BACKSPACE && ipManual.length() > 0) {
      ipManual = ipManual.substring(0, ipManual.length() - 1);
    } else if (key == ENTER || key == RETURN) {
      estadoConexion = "Conectando a " + ipManual + "...";
      thread("conectarManual");
    }
    return;
  }
  
  if (key < 256) teclas[key] = true;
  if (keyCode < 256) teclas[keyCode] = true;
}

void keyReleased() {
  if (key < 256) teclas[key] = false;
  if (keyCode < 256) teclas[keyCode] = false;
}

void dibujarPlataformas() {
  stroke(255); strokeWeight(3); fill(100); rectMode(CORNER);
  rect(0, ALTO - 50, ANCHO, 50); rect(300, 400, 400, 20);         
}

void dibujarUI() {
  rectMode(CORNER); stroke(255); strokeWeight(3);
  fill(0); rect(50, 20, 200, 20); 
  fill(255, 0, 0); rect(50, 20, max(0, j1.vida) * 2, 20); 
  fill(0); rect(ANCHO - 250, 20, 200, 20); 
  float anchoVidaJ2 = max(0, j2.vida) * 2;
  fill(50, 100, 255); rect(ANCHO - 50 - anchoVidaJ2, 20, anchoVidaJ2, 20); 
}
