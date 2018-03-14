var web3utils = require('web3-utils');
var seedrandom = require('seedrandom');
var gm = require('gm').subClass({imageMagick: true})

//be deterministically random
var randomSeed = 1011310;

var rng = seedrandom(randomSeed);


var imageMap = require("./image-map").map;

var basesCount = imageMap.bases.length;
var variantsCount = imageMap.base_variants.length;
var attachmentsCount = imageMap.attachments.length;




var renderCount = 1000;

var plannedRenders = [];

function init()
{
  var uniqueHeroes = [];
  var heroFingerprints = [];


  for(var i=0;i<renderCount;i++)
  {
    var newHero = {id: i};
    newHero.dna = Math.floor(rng() * 1e16);
    newHero.components = buildComponents(newHero.dna);


    newHero.fingerprint = web3utils.sha3(JSON.stringify(newHero.components))


    if(!heroFingerprints.includes(newHero.fingerprint))
    {
      heroFingerprints.push(newHero.fingerprint);
      uniqueHeroes.push(newHero);

      //console.log(JSON.stringify(newHero));
    }else{
        console.log("not adding duplicate", JSON.stringify(newHero));
    }
    //JSON.stringify(newHero)
  }



  //generate PNGs
  //uniqueHeroes.map


  var bgImage = './img/hero_base_dark_none.png',
      frontImage = './img/hero_back_blue_glow.png',
      resultImage = './img/result.png',
      xy = '+0+0';

  gm(bgImage)
    .composite(frontImage)
    .geometry(xy)
    .write(resultImage, function (err) {
      if (!err){
        console.log('All done');
      }else{
        console.log(err);
      }
    });

}


function buildComponents(dna)
{

  var components = {};

 //select a base
  var baseSelector = (dna/1771) % 100;
  var raritySum = 0;
  for(var j=0;j<basesCount;j++)
  {
    var base = imageMap.bases[j];
    raritySum += base.rarity;
    if(baseSelector < raritySum){
      components.baseComponent = base;
      break;
    }
  }

  //select a base variant
   var variantSelector = (dna/7352) % 100;
   var raritySum = 0;
   for(var j=0;j<variantsCount;j++)
   {
     var variant = imageMap.base_variants[j];
     raritySum += variant.rarity;
     if(variantSelector < raritySum){
       components.baseVariantComponent = variant;
       break;
     }
   }

   components.attachments = [];

   //add attachments
   addAttachments(dna/61231,components,"head");
   addAttachments(dna/1241,components,"back");
   addAttachments(dna/84556,components,"weapon");
   addAttachments(dna/6321,components,"magic");
   addAttachments(dna/1892,components,"bonus");
   addAttachments(dna/1731,components,"marking");

  return components;
}

function addAttachments(subDNA,components,type)
{
  var attachment = imageMap.attachments.find(function(element) {
      return element.name == type
    });


  if(attachment.requires_variant != null && attachment.requires_variant != components.baseVariantComponent.name ){
  //  console.log('does not support this type')
    return;
  }


  var itemSelector = (subDNA) % 100;
  var raritySum = 0;
  for(var j=0;j<attachment.items.length;j++)
  {
    var item = attachment.items[j];
    raritySum += item.rarity;
    if(itemSelector < raritySum){
      components.attachments.push(item) ;
      //console.log('attach',attachment)
      break;
    }
  }






}



init();
