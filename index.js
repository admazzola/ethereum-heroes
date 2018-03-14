
var seedrandom = require('seedrandom');

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
  for(var i=0;i<renderCount;i++)
  {
    var newHero = {id: i};
    newHero.dna = Math.floor(rng() * 1e16);
    newHero.components = buildComponents(newHero.dna);
    console.log(newHero);
  }


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

   //add attachments
   addAttachments(dna,components,"head");
   addAttachments(dna,components,"back");
   addAttachments(dna,components,"weapon");
   addAttachments(dna,components,"magic");
   addAttachments(dna,components,"bonus");
   addAttachments(dna,components,"marking");

  return components;
}

function addAttachments(dna,components,type)
{
  var attachment = imageMap.attachments.find(function(element) {
      return element.name == type
    });


  if(attachment.requires_variant != null && attachment.requires_variant != components.baseVariantComponent.name ){
    console.log('does not support this type')
    return;
  }

   console.log('attach',attachment)

}



init();
