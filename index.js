
var seedrandom = require('seedrandom');

//be deterministically random
var randomSeed = 1011310;

var rng = seedrandom(randomSeed);


var imageMap = require("./image-map").map;



var renderCount = 1000;

var plannedRenders = [];

function init()
{
  for(var i=0;i<renderCount;i++)
  {
    var newHero = {id: i};
    newHero.dna = Math.floor(rng() * 1e16);

    console.log(newHero)
  }


}


init();
