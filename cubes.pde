import ddf.minim.*;
import ddf.minim.analysis.*;


/* THINGS TO REPLACE
   murs = walls 
*/

Minim minim;
AudioPlayer song;
FFT fft;


//Variables that define the "zones" of the spectrum
//For example, for bass, we take only the first 4% of the total spectrum
float specLow = 0.03; // 3%
float specMid = 0.125;  // 12.5%
float specHi = 0.20;   // 20%

//This leaves 64% of the possible spectrum that will not be used.
//These values ​​are usually too high for the human ear anyway.

// Scoring values ​​for each zone
float scoreLow = 0;
float scoreMid = 0;
float scoreHi = 0;

// Previous value, to soften the reduction
float oldScoreLow = scoreLow;
float oldScoreMid = scoreMid;
float oldScoreHi = scoreHi;

// Softening value
float scoreDecreaseRate = 25;

// Cubes appearing in space
int nbCubes;
Cube[] cubes;

//Lines that appear on the sides
int nbMurs = 500;
Mur[] murs;

void setup()
{
  //Display in 3D on the entire screen
  fullScreen(P3D);

  //Load the minim library
  minim = new Minim(this);

  //Load song
  song = minim.loadFile("song.mp3");

  //Create the FFT object to analyze the song
  fft = new FFT(song.bufferSize(), song.sampleRate());

  //One cube per frequency band
  nbCubes = (int)(fft.specSize()*specHi);
  cubes = new Cube[nbCubes];

  //As many walls as we want
  murs = new Mur[nbMurs];

  //Create all objects
  //Create cubic objects
  for (int i = 0; i < nbCubes; i++) {
   cubes[i] = new Cube();
  }

  //Create wall objects
  //Murs gauches
  for (int i = 0; i < nbMurs; i+=4) {
   murs[i] = new Mur(0, height/2, 10, height);
  }

  //straight walls
  for (int i = 1; i < nbMurs; i+=4) {
   murs[i] = new Mur(width, height/2, 10, height);
  }

  //low walls
  for (int i = 2; i < nbMurs; i+=4) {
   murs[i] = new Mur(width/2, height, width, 10);
  }

  //High walls
  for (int i = 3; i < nbMurs; i+=4) {
   murs[i] = new Mur(width/2, 0, width, 10);
  }

  //Black backgroud
  background(0);

  //Start song
  song.play(0);
}

void draw()
{
  //advance the song. One draw () for each "frame" of the song

  fft.forward(song.mix);

  //Calculation of "scores" (power) for three categories of sound
  //D'abord, sauvgarder les anciennes valeurs
  oldScoreLow = scoreLow;
  oldScoreMid = scoreMid;
  oldScoreHi = scoreHi;

  //Reset values
  scoreLow = 0;
  scoreMid = 0;
  scoreHi = 0;

  //Calculate new scores
  for(int i = 0; i < fft.specSize()*specLow; i++)
  {
    scoreLow += fft.getBand(i);
  }

  for(int i = (int)(fft.specSize()*specLow); i < fft.specSize()*specMid; i++)
  {
    scoreMid += fft.getBand(i);
  }

  for(int i = (int)(fft.specSize()*specMid); i < fft.specSize()*specHi; i++)
  {
    scoreHi += fft.getBand(i);
  }

  //To slow down the descent
  if (oldScoreLow > scoreLow) {
    scoreLow = oldScoreLow - scoreDecreaseRate;
  }

  if (oldScoreMid > scoreMid) {
    scoreMid = oldScoreMid - scoreDecreaseRate;
  }

  if (oldScoreHi > scoreHi) {
    scoreHi = oldScoreHi - scoreDecreaseRate;
  }

  //Volume for all frequencies at this time, with the highest sounds higher
  //This allows the animation to go faster for the higher pitched sounds, which is more noticeable
  float scoreGlobal = 0.66*scoreLow + 0.8*scoreMid + 1*scoreHi;

  //Subtle color of background
  background(scoreLow/100, scoreMid/100, scoreHi/100);

  //Cube for each frequency band
  for(int i = 0; i < nbCubes; i++)
  {
    //Value of the frequency band
    float bandValue = fft.getBand(i);

    //The color is represented as: red for bass, green for medium sounds and blue for high.
    //The opacity is determined by the volume of the tape and the overall volume.
    cubes[i].display(scoreLow, scoreMid, scoreHi, bandValue, scoreGlobal);
  }

  //Walls lines, here we must keep the value of the previous tape and the next to connect them together
  float previousBandValue = fft.getBand(0);

  //Distance between each line point, negative because on the z dimension
  float dist = -25;

  //Multiply the height by this constant
  float heightMult = 2;

  //For each band
  for(int i = 1; i < fft.specSize(); i++)
  {
    //Value of the frequency band, we multiply the bands farther to make them more visible.
    float bandValue = fft.getBand(i)*(1 + (i/50));

    //Selection de la couleur en fonction des forces des différents types de sons
    stroke(100+scoreLow, 100+scoreMid, 100+scoreHi, 255-i);
    strokeWeight(1 + (scoreGlobal/100));

    //Lower left line
    line(0, height-(previousBandValue*heightMult), dist*(i-1), 0, height-(bandValue*heightMult), dist*i);
    line((previousBandValue*heightMult), height, dist*(i-1), (bandValue*heightMult), height, dist*i);
    line(0, height-(previousBandValue*heightMult), dist*(i-1), (bandValue*heightMult), height, dist*i);

    //upper left line
    line(0, (previousBandValue*heightMult), dist*(i-1), 0, (bandValue*heightMult), dist*i);
    line((previousBandValue*heightMult), 0, dist*(i-1), (bandValue*heightMult), 0, dist*i);
    line(0, (previousBandValue*heightMult), dist*(i-1), (bandValue*heightMult), 0, dist*i);

    //lower right line
    line(width, height-(previousBandValue*heightMult), dist*(i-1), width, height-(bandValue*heightMult), dist*i);
    line(width-(previousBandValue*heightMult), height, dist*(i-1), width-(bandValue*heightMult), height, dist*i);
    line(width, height-(previousBandValue*heightMult), dist*(i-1), width-(bandValue*heightMult), height, dist*i);

    //upper right line
    line(width, (previousBandValue*heightMult), dist*(i-1), width, (bandValue*heightMult), dist*i);
    line(width-(previousBandValue*heightMult), 0, dist*(i-1), width-(bandValue*heightMult), 0, dist*i);
    line(width, (previousBandValue*heightMult), dist*(i-1), width-(bandValue*heightMult), 0, dist*i);

    //save value for next loop round
    previousBandValue = bandValue;
  }

  //rectangualr walls
  for(int i = 0; i < nbMurs; i++)
  {
    //Each wall is assigned a band, and its strength is sent to it.
    float intensity = fft.getBand(i%((int)(fft.specSize()*specHi)));
    murs[i].display(scoreLow, scoreMid, scoreHi, intensity, scoreGlobal);
  }
}

//Class for cubes floating in space
class Cube {
  //Position Z de "spawn" et position Z maximale
  float startingZ = -10000;
  float maxZ = 1000;

  //coordinate values
  float x, y, z;
  float rotX, rotY, rotZ;
  float sumRotX, sumRotY, sumRotZ;

  //constructor
  Cube() {
    //Faire apparaitre le cube à un endroit aléatoire
    x = random(0, width);
    y = random(0, height);
    z = random(startingZ, maxZ);

    //give cube a random rotation for extra cool
    rotX = random(0, 1);
    rotY = random(0, 1);
    rotZ = random(0, 1);
  }

  void display(float scoreLow, float scoreMid, float scoreHi, float intensity, float scoreGlobal) {
    //Selection of the color, opacity determined by the intensity (volume of the band)
    color displayColor = color(scoreLow*0.67, scoreMid*0.67, scoreHi*0.67, intensity*5);
    fill(displayColor, 255);

    //Color lines, they disappear with the individual intensity of the cube
    color strokeColor = color(255, 150-(20*intensity));
    stroke(strokeColor);
    strokeWeight(1 + (scoreGlobal/300));

    //Creating a transformation matrix to perform rotations, enlargements
    pushMatrix();

    //Displacement
    translate(x, y, z);

    //Calculation of the rotation according to the intensity for the cube
    sumRotX += intensity*(rotX/1000);
    sumRotY += intensity*(rotY/1000);
    sumRotZ += intensity*(rotZ/1000);

    //Application of the rotation
    rotateX(sumRotX);
    rotateY(sumRotY);
    rotateZ(sumRotZ);

    //Creation of the box, variable size according to the intensity for the cube
    box(100+(intensity/2));

    //Application of the matrix
    popMatrix();

    //z displacement
    z+= (1+(intensity/5)+(pow((scoreGlobal/150), 2)));

    //Replace the box at the back when it is no longer visible
    if (z >= maxZ) {
      x = random(0, width);
      y = random(0, height);
      z = startingZ;
    }
  }
}


//Class to display the lines on the sides
class Mur {
  //Min and max position of z
  float startingZ = -10000;
  float maxZ = 50;

  //coordinate values
  float x, y, z;
  float sizeX, sizeY;

  //Constructor
  Mur(float x, float y, float sizeX, float sizeY) {
    //Make the line appear at the specified place
    this.x = x;
    this.y = y;
    //Rendering depth
    this.z = random(startingZ, maxZ);

    //We determine the size because the walls on the floors have a different size than those on the sides
    this.sizeX = sizeX;
    this.sizeY = sizeY;
  }

  //Display function
  void display(float scoreLow, float scoreMid, float scoreHi, float intensity, float scoreGlobal) {
    //Color determined by low, medium and high sounds
    //Opacity determined by the overall volume
    color displayColor = color(scoreLow*0.67, scoreMid*0.67, scoreHi*0.67, scoreGlobal);

    //Make lines disappear in the distance to give an illusion of fog
    fill(displayColor, ((scoreGlobal-5)/1000)*(255+(z/25)));
    noStroke();

    //First band, the one that moves according to the force
    //Transformation Matrix
    pushMatrix();

    //Displacement
    translate(x, y, z);

    //extension
    if (intensity > 100) intensity = 100;
    scale(sizeX*(intensity/100), sizeY*(intensity/100), 20);

    //Create box
    box(1);
    popMatrix();

    //Second band, the one that is still the same size
    displayColor = color(scoreLow*0.5, scoreMid*0.5, scoreHi*0.5, scoreGlobal);
    fill(displayColor, (scoreGlobal/5000)*(255+(z/25)));
    //Transformation matrix
    pushMatrix();

    //displacement
    translate(x, y, z);

    //extension
    scale(sizeX, sizeY, 10);

    //creation of box
    box(1);
    popMatrix();

    //displacement z
    z+= (pow((scoreGlobal/150), 2));
    if (z >= maxZ) {
      z = startingZ;
    }
  }
}
