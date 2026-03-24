import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/ingredient_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Local fallback dataset – mirrors what is seeded to Firestore
// ─────────────────────────────────────────────────────────────────────────────
const _kLocalIngredients = <String, Map<String, dynamic>>{
  'sugar': {
    'risk': 'Caution',
    'description': 'High sugar can cause blood-sugar spikes.',
    'explanation':
        'Sugar is a simple carbohydrate added to many processed foods. Excess consumption is linked to obesity, diabetes, and dental problems.',
    'regulatory':
        'Permitted in food but WHO recommends limiting free sugars to <10% of total energy intake.',
    'allergenKey': null,
    'conditionKey': 'Diabetes',
    'category': 'Sweetener',
  },
  'high fructose corn syrup': {
    'risk': 'Risky',
    'description': 'Highly processed sweetener linked to metabolic disorders.',
    'explanation':
        'HFCS is metabolized primarily by the liver and strongly associated with non-alcoholic fatty liver disease, insulin resistance, and obesity.',
    'regulatory':
        'Legal in most countries but heavily debated. Many health systems advise minimizing intake.',
    'allergenKey': null,
    'conditionKey': 'Diabetes',
    'category': 'Sweetener',
  },
  'milk': {
    'risk': 'Caution',
    'description': 'Contains lactose and dairy proteins.',
    'explanation':
        'Milk is a common allergen and may trigger symptoms in people with lactose intolerance or dairy allergy.',
    'regulatory': 'Must be declared as a major allergen on product labels.',
    'allergenKey': 'Dairy',
    'conditionKey': 'Lactose Intolerance',
    'category': 'Dairy',
  },
  'milk solids': {
    'risk': 'Caution',
    'description': 'Concentrated dairy — contains lactose and casein.',
    'explanation':
        'Milk solids retain all proteins and sugars of liquid milk, making them a potent trigger for people with dairy allergy or lactose intolerance.',
    'regulatory': 'Must be declared as a major allergen on product labels.',
    'allergenKey': 'Dairy',
    'conditionKey': 'Lactose Intolerance',
    'category': 'Dairy',
  },
  'skim milk': {
    'risk': 'Caution',
    'description': 'Low-fat milk — still contains lactose and dairy proteins.',
    'explanation':
        'Skim milk retains all dairy proteins including casein and whey. Problematic for dairy-allergic and lactose-intolerant users.',
    'regulatory': 'Must be declared as a major allergen.',
    'allergenKey': 'Dairy',
    'conditionKey': 'Lactose Intolerance',
    'category': 'Dairy',
  },
  'lactose': {
    'risk': 'Caution',
    'description': 'Milk sugar — problematic for lactose intolerant users.',
    'explanation':
        'Lactose is the primary sugar in milk. People lacking the lactase enzyme experience bloating, cramps, and diarrhea after consumption.',
    'regulatory': 'Must be declared when dairy is a major allergen.',
    'allergenKey': 'Dairy',
    'conditionKey': 'Lactose Intolerance',
    'category': 'Dairy',
  },
  'gluten': {
    'risk': 'Risky',
    'description':
        'Wheat protein — triggers celiac disease and gluten sensitivity.',
    'explanation':
        'Gluten causes an autoimmune reaction in people with celiac disease, damaging the small intestine. Even trace amounts can be harmful.',
    'regulatory':
        'Products must label gluten-containing grains. "Gluten-Free" certification requires <20 ppm.',
    'allergenKey': 'Gluten',
    'conditionKey': null,
    'category': 'Allergen',
  },
  'wheat': {
    'risk': 'Caution',
    'description':
        'Contains gluten — avoid if you have celiac or wheat allergy.',
    'explanation':
        'Wheat is one of the top 9 major food allergens and is the primary source of gluten in the diet.',
    'regulatory': 'Must be declared as a major allergen.',
    'allergenKey': 'Gluten',
    'conditionKey': null,
    'category': 'Allergen',
  },
  'wheat flour': {
    'risk': 'Caution',
    'description': 'All-purpose wheat flour — contains gluten.',
    'explanation':
        'Wheat flour is a staple ingredient containing significant amounts of gluten. Unsuitable for celiac disease or wheat allergy sufferers.',
    'regulatory': 'Must be declared as a major allergen.',
    'allergenKey': 'Gluten',
    'conditionKey': null,
    'category': 'Grain',
  },
  'soy': {
    'risk': 'Caution',
    'description': 'Common plant-based allergen.',
    'explanation':
        'Soy is among the top 9 allergens. Symptoms range from mild hives to severe anaphylaxis in sensitive individuals.',
    'regulatory': 'Must be declared as a major allergen.',
    'allergenKey': 'Soy',
    'conditionKey': null,
    'category': 'Allergen',
  },
  'soybean oil': {
    'risk': 'Safe',
    'description':
        'Refined soybean oil — generally safe even for soy-allergic individuals.',
    'explanation':
        'Highly refined soybean oil has most soy proteins removed. The FDA exempts it from soy allergen labeling, though unrefined versions should be avoided.',
    'regulatory':
        'Exempt from soy allergen labeling in the US when highly refined.',
    'allergenKey': null,
    'conditionKey': null,
    'category': 'Oil',
  },
  'egg': {
    'risk': 'Caution',
    'description': 'Egg protein — common allergen, especially in children.',
    'explanation':
        'Egg allergy is one of the most common food allergies. Both egg white and yolk proteins can trigger reactions.',
    'regulatory': 'Must be declared as a major allergen.',
    'allergenKey': 'Egg',
    'conditionKey': null,
    'category': 'Allergen',
  },
  'nuts': {
    'risk': 'Risky',
    'description': 'Tree nuts — serious allergen, risk of anaphylaxis.',
    'explanation':
        'Tree nut allergies are lifelong for most people and can cause severe systemic reactions even from trace exposure.',
    'regulatory':
        'Must be prominently declared. Cross-contact warnings required.',
    'allergenKey': 'Nuts',
    'conditionKey': null,
    'category': 'Allergen',
  },
  'peanut': {
    'risk': 'Risky',
    'description': 'Peanuts — one of the most severe allergens.',
    'explanation':
        'Peanut allergy affects approximately 1–3% of the population. Reactions can be life-threatening and often persist into adulthood.',
    'regulatory':
        'Must be declared as a major allergen. Facilities must disclose cross-contact.',
    'allergenKey': 'Nuts',
    'conditionKey': null,
    'category': 'Allergen',
  },
  'shellfish': {
    'risk': 'Risky',
    'description': 'Shellfish — common trigger for severe allergic reactions.',
    'explanation':
        'Shellfish allergy is a lifelong condition in most adults. Tropomyosin is the key protein responsible for most reactions.',
    'regulatory': 'Must be declared as a major allergen.',
    'allergenKey': 'Shellfish',
    'conditionKey': null,
    'category': 'Allergen',
  },
  'sodium': {
    'risk': 'Caution',
    'description': 'High sodium contributes to hypertension.',
    'explanation':
        'Excess dietary sodium raises blood pressure, increasing the risk of heart disease and stroke. Processed foods are a major source.',
    'regulatory': 'WHO recommends <2g sodium (<5g salt) per day for adults.',
    'allergenKey': null,
    'conditionKey': 'High Blood Pressure',
    'category': 'Mineral',
  },
  'salt': {
    'risk': 'Caution',
    'description': 'High salt intake is linked to hypertension.',
    'explanation':
        'Salt is ~40% sodium. Regular high intake is one of the leading causes of elevated blood pressure and cardiovascular disease.',
    'regulatory': 'WHO recommends limiting daily intake to 5g of salt.',
    'allergenKey': null,
    'conditionKey': 'High Blood Pressure',
    'category': 'Mineral',
  },
  'saturated fat': {
    'risk': 'Caution',
    'description': 'Linked to elevated LDL and heart disease risk.',
    'explanation':
        'Saturated fats raise LDL (bad) cholesterol. Regular excess consumption is associated with increased cardiovascular risk.',
    'regulatory':
        'Dietary guidelines recommend saturated fat <10% of total daily calories.',
    'allergenKey': null,
    'conditionKey': 'Heart Condition',
    'category': 'Fat',
  },
  'palm oil': {
    'risk': 'Caution',
    'description': 'High in saturated fat — moderate cardiovascular concern.',
    'explanation':
        'Palm oil contains ~50% saturated fat. Regular consumption may elevate LDL cholesterol levels, though it also contains beneficial vitamin E.',
    'regulatory':
        'Requires declaration on food labels. Environmental concerns documented.',
    'allergenKey': null,
    'conditionKey': 'Heart Condition',
    'category': 'Fat',
  },
  'trans fat': {
    'risk': 'Risky',
    'description': 'Artificial trans fats — the most harmful dietary fat.',
    'explanation':
        'Industrial trans fats raise LDL and lower HDL cholesterol simultaneously, dramatically increasing the risk of heart disease.',
    'regulatory':
        'Banned or severely restricted in many countries. WHO calls for global elimination from food supply.',
    'allergenKey': null,
    'conditionKey': 'Heart Condition',
    'category': 'Fat',
  },
  'partially hydrogenated oil': {
    'risk': 'Risky',
    'description': 'Major source of artificial trans fats.',
    'explanation':
        'Partial hydrogenation creates trans fatty acids that are strongly linked to heart disease. The FDA has revoked GRAS status for partially hydrogenated oils.',
    'regulatory': 'Effectively banned in the US, EU, and many other countries.',
    'allergenKey': null,
    'conditionKey': 'Heart Condition',
    'category': 'Fat',
  },
  'msg': {
    'risk': 'Caution',
    'description':
        'Monosodium glutamate — flavor enhancer; sensitivity varies.',
    'explanation':
        'MSG is a widely used flavor enhancer. While generally recognized as safe (GRAS), some individuals report sensitivity symptoms like headaches and flushing.',
    'regulatory':
        'Approved by FDA; must be listed on ingredient labels in most countries.',
    'allergenKey': null,
    'conditionKey': null,
    'category': 'Additive',
  },
  'e621': {
    'risk': 'Risky',
    'description': 'E621 (MSG) — additive linked to sensitivity reactions.',
    'explanation':
        'E621 is the European code for monosodium glutamate. Despite being approved, there are ongoing debates about its effects at high doses.',
    'regulatory':
        'Approved for use in the EU with quantity limits in certain product categories.',
    'allergenKey': null,
    'conditionKey': null,
    'category': 'Additive',
  },
  'e102': {
    'risk': 'Risky',
    'description':
        'Tartrazine (Yellow #5) — artificial colorant; may cause hyperactivity.',
    'explanation':
        'E102 is an azo dye linked to hyperactivity in children. It was part of the "Southampton six" colors that triggered UK regulatory concern.',
    'regulatory':
        'EU requires warning label: "may have an adverse effect on activity and attention in children." Banned in Norway and Austria.',
    'allergenKey': 'Artificial Colors',
    'conditionKey': null,
    'category': 'Colorant',
  },
  'artificial color': {
    'risk': 'Caution',
    'description':
        'Synthetic dyes — may trigger sensitivity in some individuals.',
    'explanation':
        'Artificial food colors are linked to behavioral effects in children and may cause allergic reactions in sensitive individuals.',
    'regulatory':
        'Approved for use but several require warning labels in the EU. Use under ongoing review.',
    'allergenKey': 'Artificial Colors',
    'conditionKey': null,
    'category': 'Colorant',
  },
  'artificial flavour': {
    'risk': 'Caution',
    'description': 'Synthetic flavor compounds — may cause sensitivities.',
    'explanation':
        'Artificial flavors are chemically synthesized flavor compounds. Most are safe at approved levels, but some individuals report sensitivities.',
    'regulatory':
        'Must be listed on labels. Specific compounds require approval in each market.',
    'allergenKey': null,
    'conditionKey': null,
    'category': 'Flavoring',
  },
  'preservative': {
    'risk': 'Caution',
    'description':
        'Chemical preservatives may cause reactions in sensitive individuals.',
    'explanation':
        'Preservatives such as benzoates, sulfites, and nitrites are used to extend shelf life. Some have been linked to allergic reactions and may affect gut microbiome.',
    'regulatory': 'Regulated with maximum permitted levels in most countries.',
    'allergenKey': null,
    'conditionKey': null,
    'category': 'Preservative',
  },
  'sodium benzoate': {
    'risk': 'Caution',
    'description':
        'Common preservative — potential carcinogen risk with vitamin C.',
    'explanation':
        'Sodium benzoate can form benzene (a known carcinogen) when combined with ascorbic acid (vitamin C) in acidic conditions. Linked to hyperactivity in children.',
    'regulatory':
        'Approved globally with concentration limits. Requires declaration on labels.',
    'allergenKey': null,
    'conditionKey': null,
    'category': 'Preservative',
  },
  'potassium sorbate': {
    'risk': 'Safe',
    'description': 'Mild preservative — generally recognized as safe.',
    'explanation':
        'Potassium sorbate inhibits mold and yeast growth. It is one of the most widely used and safest preservatives in the food industry.',
    'regulatory': 'GRAS status in the US. Approved in the EU and globally.',
    'allergenKey': null,
    'conditionKey': null,
    'category': 'Preservative',
  },
  'cocoa butter': {
    'risk': 'Safe',
    'description': 'Natural fat from cocoa beans — generally well tolerated.',
    'explanation':
        'Cocoa butter is a natural fat composed mostly of stearic acid and oleic acid. It has a neutral effect on blood cholesterol.',
    'regulatory':
        'No regulatory restrictions. Recognized as a natural food-grade fat.',
    'allergenKey': null,
    'conditionKey': null,
    'category': 'Fat',
  },
  'cocoa powder': {
    'risk': 'Safe',
    'description': 'Antioxidant-rich cocoa solids.',
    'explanation':
        'Cocoa powder is rich in flavonoids and antioxidants. Associated with cardiovascular benefits. Contains small amounts of caffeine.',
    'regulatory': 'Natural food ingredient with no regulatory restrictions.',
    'allergenKey': null,
    'conditionKey': null,
    'category': 'Natural',
  },
  'lecithin': {
    'risk': 'Safe',
    'description': 'Natural emulsifier — soy or sunflower derived.',
    'explanation':
        'Lecithin is a phospholipid used as an emulsifier. It is generally recognized as safe (GRAS) and used in very small quantities.',
    'regulatory':
        'Approved globally. Highly refined soy lecithin is unlikely to trigger soy allergy.',
    'allergenKey': null,
    'conditionKey': null,
    'category': 'Emulsifier',
  },
  'sunflower oil': {
    'risk': 'Safe',
    'description': 'Healthy vegetable oil rich in vitamin E.',
    'explanation':
        'Sunflower oil is high in unsaturated fats and vitamin E. When not overheated, it is a heart-healthy cooking oil.',
    'regulatory': 'Natural food ingredient with no regulatory restrictions.',
    'allergenKey': null,
    'conditionKey': null,
    'category': 'Oil',
  },
  'vitamin c': {
    'risk': 'Safe',
    'description': 'Ascorbic acid — antioxidant, essential vitamin.',
    'explanation':
        'Vitamin C (ascorbic acid) is an essential nutrient and antioxidant. When used as an additive (E300), it also acts as a natural preservative.',
    'regulatory': 'Recognized as safe worldwide. No regulatory restrictions.',
    'allergenKey': null,
    'conditionKey': null,
    'category': 'Vitamin',
  },
  'vitamin e': {
    'risk': 'Safe',
    'description': 'Tocopherol — fat-soluble antioxidant.',
    'explanation':
        'Vitamin E protects cells from oxidative stress. As a food additive (E306-309), it prevents rancidity in oils and fats.',
    'regulatory': 'Recognized as safe worldwide. No regulatory restrictions.',
    'allergenKey': null,
    'conditionKey': null,
    'category': 'Vitamin',
  },
  'calcium carbonate': {
    'risk': 'Safe',
    'description': 'Mineral supplement and anti-caking agent.',
    'explanation':
        'Calcium carbonate is a natural source of calcium used to supplement food and prevent clumping. Safe at approved levels.',
    'regulatory': 'Recognized as safe globally.',
    'allergenKey': null,
    'conditionKey': null,
    'category': 'Mineral',
  },
  'natural flavour': {
    'risk': 'Safe',
    'description': 'Flavoring derived from natural sources.',
    'explanation':
        'Natural flavors are derived from plant or animal sources. Generally considered safer than artificial alternatives. Exact compounds vary.',
    'regulatory':
        'Must be listed on labels. Sources must be natural per regulatory definition.',
    'allergenKey': null,
    'conditionKey': null,
    'category': 'Flavoring',
  },
  'water': {
    'risk': 'Safe',
    'description': 'Purified water — safe for all consumers.',
    'explanation':
        'Water is added to maintain product consistency and moisture. Has no health concerns.',
    'regulatory': 'No restrictions.',
    'allergenKey': null,
    'conditionKey': null,
    'category': 'Base',
  },

  // ── NEW INGREDIENTS ──────────────────────────────────────────────────────

  // Sweeteners
  'aspartame': {
    'risk': 'Caution',
    'description':
        'Artificial sweetener — contraindicated in phenylketonuria (PKU).',
    'explanation':
        'Aspartame is broken down into phenylalanine, aspartic acid, and methanol. People with PKU cannot metabolize phenylalanine safely. Approved for general population at regulated doses.',
    'regulatory':
        'FDA-approved with an ADI of 50 mg/kg body weight. Must carry a PKU warning on labels. EU ADI is 40 mg/kg.',
    'allergenKey': null,
    'conditionKey': 'PKU',
    'category': 'Sweetener',
  },
  'sucralose': {
    'risk': 'Safe',
    'description':
        'Zero-calorie artificial sweetener — generally well tolerated.',
    'explanation':
        'Sucralose is a chlorinated sucrose derivative. It is not metabolized for energy and passes through the body largely unchanged. Some studies suggest possible effects on gut microbiota at very high doses.',
    'regulatory':
        'FDA GRAS. Approved in over 80 countries. ADI set at 5 mg/kg body weight.',
    'allergenKey': null,
    'conditionKey': null,
    'category': 'Sweetener',
  },
  'stevia': {
    'risk': 'Safe',
    'description': 'Plant-derived sweetener — zero glycemic impact.',
    'explanation':
        'Stevia glycosides are extracted from the Stevia rebaudiana plant. They have no caloric value and do not raise blood glucose, making them suitable for diabetics.',
    'regulatory':
        'Approved by FDA (GRAS), EFSA, and most global regulators. Acceptable daily intake established.',
    'allergenKey': null,
    'conditionKey': null,
    'category': 'Sweetener',
  },
  'sorbitol': {
    'risk': 'Caution',
    'description':
        'Sugar alcohol — can cause digestive discomfort at high doses.',
    'explanation':
        'Sorbitol is a sugar alcohol used as a low-calorie sweetener. Excess consumption (>20g/day) causes osmotic diarrhea, bloating, and gas. Used in sugar-free products.',
    'regulatory':
        'Approved globally. EU requires "excessive consumption may produce laxative effects" label when >10g/day portion.',
    'allergenKey': null,
    'conditionKey': 'IBS',
    'category': 'Sweetener',
  },
  'maltitol': {
    'risk': 'Caution',
    'description':
        'Sugar alcohol — partially raises blood sugar; laxative in excess.',
    'explanation':
        'Maltitol has a glycemic index of ~35, meaning it partially raises blood glucose — less than sugar but not negligible for diabetics. Also a laxative at high doses.',
    'regulatory':
        'Approved globally. Laxative warning required at high consumption levels in the EU.',
    'allergenKey': null,
    'conditionKey': 'Diabetes',
    'category': 'Sweetener',
  },
  'xylitol': {
    'risk': 'Caution',
    'description': 'Sugar alcohol — safe for humans, highly toxic to dogs.',
    'explanation':
        'Xylitol has a low glycemic index and promotes dental health. However, it causes life-threatening hypoglycemia in dogs. Human tolerance is generally good but high doses cause digestive discomfort.',
    'regulatory':
        'Approved for human food globally. Pet safety warnings increasingly required.',
    'allergenKey': null,
    'conditionKey': null,
    'category': 'Sweetener',
  },

  // Grains & Starches
  'modified starch': {
    'risk': 'Safe',
    'description':
        'Chemically or physically modified starch — used as thickener.',
    'explanation':
        'Modified starches are derived from corn, wheat, potato, or tapioca and processed to improve stability. Generally recognized as safe. May be derived from wheat (relevant for celiac sufferers).',
    'regulatory':
        'Must declare source grain if derived from a major allergen. GRAS in the US.',
    'allergenKey': 'Gluten',
    'conditionKey': null,
    'category': 'Grain',
  },
  'cornstarch': {
    'risk': 'Safe',
    'description': 'Gluten-free thickener derived from corn.',
    'explanation':
        'Cornstarch is a refined starch with no protein. It is naturally gluten-free and safe for celiac patients unless cross-contaminated.',
    'regulatory': 'Natural food ingredient. No restrictions.',
    'allergenKey': null,
    'conditionKey': null,
    'category': 'Grain',
  },
  'oats': {
    'risk': 'Caution',
    'description': 'Oats — naturally gluten-free but often cross-contaminated.',
    'explanation':
        'Oats do not contain gluten intrinsically but are frequently processed alongside wheat, barley, and rye, causing cross-contamination. Certified gluten-free oats are available.',
    'regulatory':
        'Must be labeled "gluten-free" to meet <20 ppm threshold. Regular oats do not qualify.',
    'allergenKey': 'Gluten',
    'conditionKey': null,
    'category': 'Grain',
  },
  'barley': {
    'risk': 'Caution',
    'description': 'Contains gluten — unsuitable for celiac disease.',
    'explanation':
        'Barley contains hordein, a form of gluten. It is commonly found in malt, beer, and soups and must be avoided by celiac and gluten-intolerant individuals.',
    'regulatory':
        'Must be declared as a gluten-containing grain on food labels.',
    'allergenKey': 'Gluten',
    'conditionKey': null,
    'category': 'Grain',
  },
  'rye': {
    'risk': 'Caution',
    'description':
        'Contains secalin — a gluten protein harmful to celiac sufferers.',
    'explanation':
        'Rye contains secalin, a prolamin related to gluten. It triggers celiac disease and non-celiac gluten sensitivity similarly to wheat gluten.',
    'regulatory':
        'Must be declared as a gluten-containing grain on food labels.',
    'allergenKey': 'Gluten',
    'conditionKey': null,
    'category': 'Grain',
  },

  // Proteins & Meat
  'whey protein': {
    'risk': 'Caution',
    'description': 'Dairy-derived protein — triggers dairy allergy.',
    'explanation':
        'Whey is a by-product of cheese production and contains dairy proteins including beta-lactoglobulin. It is a potent allergen for dairy-allergic individuals.',
    'regulatory': 'Must be declared as a dairy allergen.',
    'allergenKey': 'Dairy',
    'conditionKey': 'Lactose Intolerance',
    'category': 'Protein',
  },
  'casein': {
    'risk': 'Caution',
    'description': 'Primary milk protein — major dairy allergen.',
    'explanation':
        'Casein constitutes 80% of milk protein and is a major trigger for IgE-mediated dairy allergy. It is present in many processed and baked goods.',
    'regulatory': 'Must be declared as a dairy allergen on all food labels.',
    'allergenKey': 'Dairy',
    'conditionKey': 'Lactose Intolerance',
    'category': 'Protein',
  },
  'fish': {
    'risk': 'Risky',
    'description':
        'Fish protein — common cause of severe, lifelong food allergy.',
    'explanation':
        'Fish allergy affects approximately 1% of the population. Parvalbumin, the main allergen, is heat-stable. Reactions can range from hives to anaphylaxis.',
    'regulatory':
        'Must be declared as a major allergen. Cross-contact risks must be disclosed.',
    'allergenKey': 'Fish',
    'conditionKey': null,
    'category': 'Allergen',
  },
  'sesame': {
    'risk': 'Caution',
    'description': 'Sesame — increasingly recognized as a top-tier allergen.',
    'explanation':
        'Sesame allergy can cause severe reactions. The US added sesame as the 9th major food allergen in 2023. It is present in many Middle Eastern, Asian, and baked food products.',
    'regulatory':
        'Now a declared major allergen in the US (FASTER Act, 2023). Also declared in the EU and Australia.',
    'allergenKey': 'Sesame',
    'conditionKey': null,
    'category': 'Allergen',
  },
  'lupin': {
    'risk': 'Caution',
    'description': 'Lupin flour — allergen cross-reactive with peanut.',
    'explanation':
        'Lupin is a legume increasingly used in gluten-free flour blends. It can cross-react with peanut allergy and cause severe reactions in peanut-allergic individuals.',
    'regulatory':
        'Declared allergen in the EU, Australia, and New Zealand. Not yet a major allergen in the US.',
    'allergenKey': 'Lupin',
    'conditionKey': null,
    'category': 'Allergen',
  },
  'celery': {
    'risk': 'Caution',
    'description':
        'Celery — declared allergen in the EU with cross-reactivity.',
    'explanation':
        'Celery allergy can manifest as oral allergy syndrome or systemic reactions. Often cross-reactive with birch pollen allergy. Common in soups, spice blends, and sauces.',
    'regulatory':
        'Declared allergen in the EU and Switzerland. Must be listed on food labels.',
    'allergenKey': 'Celery',
    'conditionKey': null,
    'category': 'Allergen',
  },
  'mustard': {
    'risk': 'Caution',
    'description':
        'Mustard seed — EU-declared allergen; risk of severe reactions.',
    'explanation':
        'Mustard allergy is particularly common in France and other parts of Europe. Reactions range from oral itching to anaphylaxis. Found in condiments, dressings, and Indian cuisine.',
    'regulatory': 'Declared allergen in the EU. Must be prominently labeled.',
    'allergenKey': 'Mustard',
    'conditionKey': null,
    'category': 'Allergen',
  },
  'sulphites': {
    'risk': 'Caution',
    'description':
        'Sulphur-based preservatives — may trigger asthma and allergy.',
    'explanation':
        'Sulphites (sulfur dioxide and its salts) are used as preservatives in wine, dried fruits, and processed meats. They can trigger asthma attacks and pseudo-allergic reactions in sensitive individuals.',
    'regulatory':
        'Declared allergen in the EU, US, and Australia when >10 ppm. Must be labeled on wine and food products.',
    'allergenKey': 'Sulphites',
    'conditionKey': 'Asthma',
    'category': 'Allergen',
  },
  'molluscs': {
    'risk': 'Risky',
    'description':
        'Molluscs — EU-declared allergen; distinct from crustacean shellfish.',
    'explanation':
        'Mollusc allergy (squid, octopus, mussels, oysters) is separate from crustacean shellfish allergy. Tropomyosin is again the primary allergen. Often lifelong and severe.',
    'regulatory': 'Declared allergen in the EU. Must be listed on food labels.',
    'allergenKey': 'Molluscs',
    'conditionKey': null,
    'category': 'Allergen',
  },

  // Fats & Oils
  'coconut oil': {
    'risk': 'Caution',
    'description': 'High in saturated fat — moderate cardiovascular concern.',
    'explanation':
        'Coconut oil is ~90% saturated fat, higher than butter or lard. While it contains medium-chain triglycerides (MCTs) that may have metabolic benefits, its effect on LDL cholesterol is a concern at high doses.',
    'regulatory':
        'No regulatory restrictions. Dietary guidelines recommend limiting saturated fat.',
    'allergenKey': null,
    'conditionKey': 'Heart Condition',
    'category': 'Fat',
  },
  'hydrogenated vegetable oil': {
    'risk': 'Risky',
    'description':
        'Fully or partially hydrogenated — potential trans fat source.',
    'explanation':
        'Depending on the degree of hydrogenation, these oils may contain trans fats. Fully hydrogenated oils have no trans fats but are solid and high in saturated fat.',
    'regulatory':
        'Partially hydrogenated oils are banned/restricted in many countries.',
    'allergenKey': null,
    'conditionKey': 'Heart Condition',
    'category': 'Fat',
  },
  'canola oil': {
    'risk': 'Safe',
    'description': 'Low in saturated fat — heart-healthy cooking oil.',
    'explanation':
        'Canola oil is derived from rapeseed and is very low in saturated fat (~7%) with a favorable omega-3 to omega-6 ratio. Widely considered one of the healthiest cooking oils.',
    'regulatory': 'Natural food ingredient. No regulatory restrictions.',
    'allergenKey': null,
    'conditionKey': null,
    'category': 'Oil',
  },
  'olive oil': {
    'risk': 'Safe',
    'description': 'Rich in monounsaturated fats — excellent for heart health.',
    'explanation':
        'Extra virgin olive oil is high in oleic acid and polyphenols. Extensively studied for cardiovascular benefits as part of the Mediterranean diet.',
    'regulatory':
        'Natural food ingredient. No regulatory restrictions. Grading standards enforced.',
    'allergenKey': null,
    'conditionKey': null,
    'category': 'Oil',
  },

  // Additives & Preservatives
  'e211': {
    'risk': 'Caution',
    'description': 'Sodium benzoate (E211) — may form benzene with vitamin C.',
    'explanation':
        'E211 is the EU code for sodium benzoate. In the presence of ascorbic acid and heat or light, it can convert to benzene. Also linked to hyperactivity in children.',
    'regulatory':
        'Approved in EU with concentration limits. Mandatory labeling required.',
    'allergenKey': null,
    'conditionKey': null,
    'category': 'Preservative',
  },
  'e220': {
    'risk': 'Caution',
    'description': 'Sulphur dioxide (E220) — preservative; declared allergen.',
    'explanation':
        'E220 is used in wines, dried fruits, and fruit juices. Can cause asthma attacks and hypersensitivity reactions in sensitive individuals.',
    'regulatory':
        'Declared allergen in EU when >10 ppm. Mandatory labeling on wine.',
    'allergenKey': 'Sulphites',
    'conditionKey': 'Asthma',
    'category': 'Preservative',
  },
  'e250': {
    'risk': 'Risky',
    'description':
        'Sodium nitrite (E250) — curing agent; potential carcinogen.',
    'explanation':
        'Sodium nitrite prevents botulism in cured meats and gives them their characteristic pink color. However, it can form N-nitrosamines, which are carcinogenic, especially when meat is cooked at high temperatures.',
    'regulatory':
        'Approved with strict maximum levels in the EU and US. WHO classifies processed meats as Group 1 carcinogens partly due to nitrites.',
    'allergenKey': null,
    'conditionKey': 'Cancer Risk',
    'category': 'Preservative',
  },
  'e320': {
    'risk': 'Caution',
    'description':
        'BHA (E320) — antioxidant preservative; possible carcinogen.',
    'explanation':
        'Butylated hydroxyanisole (BHA) is used to prevent fat rancidity. It is listed as a possible carcinogen by the IARC (Group 2B) and is banned or restricted in several countries.',
    'regulatory':
        'Approved in the US and EU with concentration limits. Banned in Japan for some applications.',
    'allergenKey': null,
    'conditionKey': 'Cancer Risk',
    'category': 'Preservative',
  },
  'e321': {
    'risk': 'Caution',
    'description':
        'BHT (E321) — antioxidant preservative; under ongoing review.',
    'explanation':
        'Butylated hydroxytoluene (BHT) is used similarly to BHA. Animal studies show endocrine-disrupting potential. The NTP classifies it as reasonably anticipated to be a carcinogen.',
    'regulatory':
        'Approved in EU and US with limits. Avoided in clean-label products.',
    'allergenKey': null,
    'conditionKey': null,
    'category': 'Preservative',
  },
  'carrageenan': {
    'risk': 'Caution',
    'description': 'Seaweed-derived thickener — may irritate the gut.',
    'explanation':
        'Carrageenan is extracted from red seaweed and used as a thickener and stabilizer. Some research suggests it may promote intestinal inflammation, though findings are debated.',
    'regulatory':
        'Approved globally. Under ongoing review by the European Food Safety Authority.',
    'allergenKey': null,
    'conditionKey': 'IBS',
    'category': 'Additive',
  },
  'titanium dioxide': {
    'risk': 'Risky',
    'description': 'E171 — white colorant; banned in the EU as food additive.',
    'explanation':
        'Titanium dioxide (E171) is used as a white coloring in sweets, chewing gum, and sauces. The EFSA concluded it cannot be considered safe as a food additive due to genotoxicity concerns.',
    'regulatory':
        'Banned as a food additive in the EU since 2022. Still permitted in the US, Canada, and many other countries.',
    'allergenKey': null,
    'conditionKey': null,
    'category': 'Colorant',
  },
  'e129': {
    'risk': 'Risky',
    'description':
        'Allura Red (E129) — artificial dye; linked to hyperactivity.',
    'explanation':
        'Allura Red is one of the Southampton six artificial dyes. Studies associate it with increased hyperactivity in children. It is an azo dye that may also trigger reactions in aspirin-sensitive individuals.',
    'regulatory':
        'EU requires hyperactivity warning label. Approved in the US (FD&C Red 40) without warning.',
    'allergenKey': 'Artificial Colors',
    'conditionKey': null,
    'category': 'Colorant',
  },
  'e110': {
    'risk': 'Risky',
    'description':
        'Sunset Yellow (E110) — synthetic dye; hyperactivity concern.',
    'explanation':
        'E110 is one of the Southampton six dyes linked to hyperactivity in children. Also known as FD&C Yellow 6 in the US. It is an azo dye that may cause reactions in aspirin-sensitive individuals.',
    'regulatory':
        'EU requires warning label about hyperactivity. Restricted in Norway.',
    'allergenKey': 'Artificial Colors',
    'conditionKey': null,
    'category': 'Colorant',
  },
  'caffeine': {
    'risk': 'Caution',
    'description':
        'Stimulant — may cause anxiety, insomnia, and elevated heart rate.',
    'explanation':
        'Caffeine is a central nervous system stimulant. At moderate levels it improves alertness. At high doses (>400mg/day for adults) it causes anxiety, insomnia, and cardiovascular stress. Not recommended for children or pregnant women.',
    'regulatory':
        'Must be labeled in soft drinks above 150 mg/L in the EU. Not regulated as allergen.',
    'allergenKey': null,
    'conditionKey': 'Anxiety Disorder',
    'category': 'Stimulant',
  },
  'alcohol': {
    'risk': 'Risky',
    'description':
        'Ethanol — toxic at high doses; contraindicated in multiple conditions.',
    'explanation':
        'Alcohol (ethanol) affects the liver, nervous system, and cardiovascular system. Even small amounts are contraindicated during pregnancy and in people with liver disease. Can interact with many medications.',
    'regulatory':
        'Heavily regulated globally. Must be labeled on products. Age restrictions apply.',
    'allergenKey': null,
    'conditionKey': 'Liver Disease',
    'category': 'Additive',
  },
  'phosphoric acid': {
    'risk': 'Caution',
    'description': 'Acidulant — may reduce bone density with high intake.',
    'explanation':
        'Phosphoric acid is used in cola drinks for a sharp, tangy flavor. High dietary phosphorus intake is associated with reduced bone mineral density and increased calcium excretion, especially when calcium intake is low.',
    'regulatory':
        'Approved globally as a food acidulant. No specific limit, but dietary guidelines advise balanced phosphorus/calcium ratio.',
    'allergenKey': null,
    'conditionKey': 'Osteoporosis',
    'category': 'Additive',
  },
  'citric acid': {
    'risk': 'Safe',
    'description': 'Natural acidulant — generally recognized as safe.',
    'explanation':
        'Citric acid occurs naturally in citrus fruits and is widely used as an acidulant, preservative, and flavor enhancer. GRAS for the general population. May erode tooth enamel in very large quantities.',
    'regulatory':
        'GRAS in the US. Approved globally with no specific intake limit.',
    'allergenKey': null,
    'conditionKey': null,
    'category': 'Additive',
  },
  'malic acid': {
    'risk': 'Safe',
    'description': 'Naturally occurring fruit acid — safe flavor enhancer.',
    'explanation':
        'Malic acid is found naturally in apples and pears. Used as an acidulant in beverages and confectionery. Well tolerated and metabolized normally.',
    'regulatory': 'Approved globally. GRAS in the US.',
    'allergenKey': null,
    'conditionKey': null,
    'category': 'Additive',
  },
  'acesulfame potassium': {
    'risk': 'Safe',
    'description': 'Acesulfame-K — zero-calorie sweetener; approved globally.',
    'explanation':
        'Acesulfame potassium is a non-nutritive sweetener approximately 200 times sweeter than sugar. It is not metabolized by the body. Some animal studies raised concerns at extremely high doses, but human data supports safety at normal intake.',
    'regulatory':
        'FDA-approved. ADI of 15 mg/kg body weight. Approved in EU and globally.',
    'allergenKey': null,
    'conditionKey': null,
    'category': 'Sweetener',
  },

  // Vitamins & Minerals
  'iron': {
    'risk': 'Safe',
    'description':
        'Essential mineral — beneficial when added for fortification.',
    'explanation':
        'Iron is an essential nutrient required for red blood cell production. As a food additive (fortification), it helps prevent iron-deficiency anemia, especially in at-risk populations.',
    'regulatory':
        'Recognized as safe globally. Upper tolerable limits established by health authorities.',
    'allergenKey': null,
    'conditionKey': null,
    'category': 'Mineral',
  },
  'zinc': {
    'risk': 'Safe',
    'description':
        'Trace mineral — supports immune function and wound healing.',
    'explanation':
        'Zinc is an essential trace element involved in enzyme activity, protein synthesis, and immune function. Used in fortified foods and supplements.',
    'regulatory': 'Recognized as safe globally.',
    'allergenKey': null,
    'conditionKey': null,
    'category': 'Mineral',
  },
  'folic acid': {
    'risk': 'Safe',
    'description':
        'B-vitamin — critical during pregnancy for neural tube development.',
    'explanation':
        'Folic acid (vitamin B9) is essential for DNA synthesis and cell division. Adequate intake before and during early pregnancy significantly reduces the risk of neural tube defects.',
    'regulatory':
        'Added to many staple foods in fortification programs. Safe at recommended levels.',
    'allergenKey': null,
    'conditionKey': null,
    'category': 'Vitamin',
  },
  'vitamin d': {
    'risk': 'Safe',
    'description': 'Fat-soluble vitamin — supports bone health and immunity.',
    'explanation':
        'Vitamin D is essential for calcium absorption and bone mineralisation. Many populations are deficient, and food fortification (milk, cereals) helps address this gap.',
    'regulatory':
        'Safe at recommended daily intakes. Upper safe limit is 4000 IU/day for adults.',
    'allergenKey': null,
    'conditionKey': null,
    'category': 'Vitamin',
  },
  'niacin': {
    'risk': 'Safe',
    'description': 'Vitamin B3 — essential for energy metabolism.',
    'explanation':
        'Niacin (nicotinic acid) is a water-soluble B vitamin required for energy production and DNA repair. Added to fortified cereals and breads. At very high supplemental doses it causes skin flushing.',
    'regulatory':
        'GRAS for food fortification. Upper tolerable limit 35 mg/day from supplements.',
    'allergenKey': null,
    'conditionKey': null,
    'category': 'Vitamin',
  },

  // Natural Ingredients
  'turmeric': {
    'risk': 'Safe',
    'description': 'Anti-inflammatory spice — natural colorant.',
    'explanation':
        'Turmeric contains curcumin, a polyphenol with well-documented anti-inflammatory and antioxidant properties. Used as a natural yellow colorant and flavoring. Safe at culinary doses.',
    'regulatory': 'Natural food ingredient. No regulatory restrictions.',
    'allergenKey': null,
    'conditionKey': null,
    'category': 'Natural',
  },
  'ginger': {
    'risk': 'Safe',
    'description': 'Digestive spice — anti-nausea and anti-inflammatory.',
    'explanation':
        'Ginger contains gingerols and shogaols with documented anti-nausea, anti-inflammatory, and digestive benefits. Safe at culinary doses. May mildly interact with blood-thinning medications at high doses.',
    'regulatory': 'Natural food ingredient. GRAS in the US.',
    'allergenKey': null,
    'conditionKey': null,
    'category': 'Natural',
  },
  'tapioca starch': {
    'risk': 'Safe',
    'description': 'Gluten-free starch from cassava — safe for celiac.',
    'explanation':
        'Tapioca starch is extracted from the cassava root and is naturally free from gluten, making it suitable for celiac disease. Used as a thickener and binding agent in gluten-free products.',
    'regulatory': 'Natural food ingredient. No regulatory restrictions.',
    'allergenKey': null,
    'conditionKey': null,
    'category': 'Natural',
  },
  'xanthan gum': {
    'risk': 'Safe',
    'description': 'Microbial polysaccharide — safe thickener and stabilizer.',
    'explanation':
        'Xanthan gum is produced by fermentation and used as a thickener, particularly in gluten-free baking. It is well tolerated by most people. Very high doses may cause digestive discomfort in sensitive individuals.',
    'regulatory':
        'GRAS in the US. Approved globally. No significant restrictions.',
    'allergenKey': null,
    'conditionKey': null,
    'category': 'Additive',
  },
  'guar gum': {
    'risk': 'Safe',
    'description': 'Plant-derived fiber — thickener with gut health benefits.',
    'explanation':
        'Guar gum is derived from guar beans and acts as a soluble dietary fiber as well as a food thickener. It may lower blood glucose and cholesterol when consumed regularly.',
    'regulatory':
        'GRAS in the US. Approved globally. FDA-mandated removal of very high dose fiber supplements in the 1980s.',
    'allergenKey': null,
    'conditionKey': null,
    'category': 'Additive',
  },
  'inulin': {
    'risk': 'Safe',
    'description': 'Prebiotic fiber — supports gut microbiome.',
    'explanation':
        'Inulin is a naturally occurring prebiotic fiber derived from chicory root. It feeds beneficial gut bacteria (Lactobacillus, Bifidobacterium) and supports digestive health. May cause gas in large amounts.',
    'regulatory':
        'Recognized as safe globally. GRAS in the US. Used in functional foods.',
    'allergenKey': null,
    'conditionKey': null,
    'category': 'Natural',
  },
  'honey': {
    'risk': 'Caution',
    'description': 'Natural sweetener — unsafe for infants under 12 months.',
    'explanation':
        'Honey is a natural sweetener with antimicrobial properties. However, it may contain Clostridium botulinum spores that can cause infant botulism in babies under one year of age.',
    'regulatory':
        'Safe for adults. Regulatory bodies globally warn against giving honey to children under 12 months.',
    'allergenKey': null,
    'conditionKey': 'Infant Safety',
    'category': 'Natural',
  },
  'maple syrup': {
    'risk': 'Caution',
    'description':
        'Natural sweetener — high sugar content; moderate glycemic index.',
    'explanation':
        'Maple syrup has a glycemic index of ~54 (lower than table sugar at ~65) and contains trace minerals and antioxidants. Still a concentrated source of sugar, unsuitable for diabetics in large quantities.',
    'regulatory': 'Natural food ingredient. Graded by purity standards.',
    'allergenKey': null,
    'conditionKey': 'Diabetes',
    'category': 'Sweetener',
  },
};

// ─────────────────────────────────────────────────────────────────────────────
// Allergen Types Dataset
// ─────────────────────────────────────────────────────────────────────────────
const _kAllergenTypes = <String, Map<String, dynamic>>{
  'Dairy': {
    'displayName': 'Dairy / Milk',
    'description': 'Proteins in cow\'s milk including casein and whey.',
    'commonSources':
        'Milk, cheese, butter, yoghurt, cream, whey protein, casein, milk solids, lactose.',
    'reactionType': 'Allergic (IgE) or intolerance (enzyme deficiency)',
    'severity': 'Mild to Severe',
    'prevalence': 'Affects ~2–3% of infants; ~0.5% of adults.',
    'avoidanceNote':
        'Check for hidden dairy in baked goods, chocolate, salad dressings, and medication coatings.',
  },
  'Gluten': {
    'displayName': 'Gluten (Wheat / Barley / Rye)',
    'description':
        'Proteins (gliadin, hordein, secalin) found in wheat, barley, rye, and often oats.',
    'commonSources':
        'Bread, pasta, cereals, beer, soy sauce, many processed foods.',
    'reactionType': 'Autoimmune (celiac) or non-celiac sensitivity',
    'severity': 'Moderate to Severe (celiac)',
    'prevalence': 'Celiac affects ~1% globally; NCGS up to 6%.',
    'avoidanceNote':
        'Look for certified gluten-free labels (<20 ppm). Beware of cross-contamination in shared kitchens.',
  },
  'Egg': {
    'displayName': 'Egg',
    'description':
        'Proteins in egg white (ovalbumin, ovomucoid) and yolk (livetin).',
    'commonSources':
        'Eggs, mayonnaise, baked goods, pasta, quiche, meringue, some vaccines.',
    'reactionType': 'Allergic (IgE-mediated)',
    'severity': 'Mild to Severe',
    'prevalence': '1–2% of children; often outgrown by adolescence.',
    'avoidanceNote':
        'Egg derivatives like albumin, globulin, lysozyme, and surimi may appear on labels.',
  },
  'Soy': {
    'displayName': 'Soy',
    'description': 'Proteins in soybeans and soy-derived products.',
    'commonSources':
        'Tofu, soy milk, edamame, miso, tempeh, many processed foods, infant formula.',
    'reactionType': 'Allergic (IgE-mediated)',
    'severity': 'Mild to Moderate (rarely severe)',
    'prevalence': '0.4% of children; often outgrown.',
    'avoidanceNote':
        'Highly refined soybean oil and soy lecithin are often tolerated. Check labels carefully.',
  },
  'Nuts': {
    'displayName': 'Tree Nuts & Peanuts',
    'description':
        'Proteins in tree nuts (almonds, cashews, walnuts, etc.) and legume-family peanuts.',
    'commonSources':
        'Nuts, nut butters, marzipan, pesto, satay, praline, many bakery items.',
    'reactionType': 'Allergic (IgE-mediated)',
    'severity': 'Severe — high anaphylaxis risk',
    'prevalence': 'Peanut: 1–3% globally; tree nuts: ~1%. Usually lifelong.',
    'avoidanceNote':
        'Cross-contact in facilities is a major concern. Carry an epinephrine auto-injector if prescribed.',
  },
  'Shellfish': {
    'displayName': 'Crustacean Shellfish',
    'description':
        'Proteins (tropomyosin) in shrimp, crab, lobster, prawns, and similar crustaceans.',
    'commonSources':
        'Shrimp, crab, lobster, prawn, crayfish, barnacles, krill.',
    'reactionType': 'Allergic (IgE-mediated)',
    'severity': 'Severe — high anaphylaxis risk',
    'prevalence': '~2% of adults; rarely outgrown.',
    'avoidanceNote':
        'Distinct from mollusc shellfish. Steam from cooking shellfish can trigger reactions.',
  },
  'Fish': {
    'displayName': 'Fish',
    'description':
        'Proteins (parvalbumin) in finfish — salmon, tuna, cod, etc.',
    'commonSources':
        'All finfish, fish sauce, Worcestershire sauce, Caesar dressing, some gelatins.',
    'reactionType': 'Allergic (IgE-mediated)',
    'severity': 'Moderate to Severe',
    'prevalence': '~1% globally; most common in adults.',
    'avoidanceNote':
        'Parvalbumin is heat-stable. Even cooked fish triggers reactions. Cross-reactivity across fish species is common.',
  },
  'Sesame': {
    'displayName': 'Sesame',
    'description':
        'Proteins (Ses i 1–7) in sesame seeds and sesame-derived products.',
    'commonSources':
        'Tahini, hummus, halva, sesame oil, breads, burger buns, Asian sauces.',
    'reactionType': 'Allergic (IgE-mediated)',
    'severity': 'Moderate to Severe',
    'prevalence': '~0.2–0.5%; growing recognition globally.',
    'avoidanceNote':
        'Added as the 9th major allergen in the US (2023). Check breads, crackers, and restaurant foods carefully.',
  },
  'Sulphites': {
    'displayName': 'Sulphites / Sulfites',
    'description': 'Sulphur dioxide and sulphite salts used as preservatives.',
    'commonSources':
        'Wine, dried fruits, fruit juices, pickled foods, processed meats, some medications.',
    'reactionType': 'Pseudo-allergic / sensitivity reaction',
    'severity': 'Mild to Moderate (asthma exacerbation risk)',
    'prevalence': '~1% of general population; ~5–10% of asthmatics.',
    'avoidanceNote':
        'Declared at >10 ppm in most jurisdictions. Look for E220–E228 on labels.',
  },
  'Lupin': {
    'displayName': 'Lupin',
    'description':
        'Proteins in lupin seeds — a legume increasingly used in flour.',
    'commonSources':
        'Lupin flour, lupin bread, pasta, pastries, veggie burgers.',
    'reactionType': 'Allergic (IgE-mediated)',
    'severity': 'Moderate to Severe (cross-reactive with peanut)',
    'prevalence':
        'Less than 1% but significant in peanut-allergic individuals.',
    'avoidanceNote':
        'EU-declared allergen. Not yet a major allergen in the US. Check gluten-free and high-protein products.',
  },
  'Celery': {
    'displayName': 'Celery',
    'description': 'Proteins in celery stalks, seeds, and leaves.',
    'commonSources':
        'Celery stalks, celeriac, celery salt, celery seed, soups, spice mixes.',
    'reactionType': 'Allergic (IgE-mediated) — often pollen-food syndrome',
    'severity': 'Mild to Severe',
    'prevalence': 'Mainly affects adults with birch pollen allergy.',
    'avoidanceNote':
        'EU-declared allergen. Common in spice blends, stock cubes, and ready meals.',
  },
  'Mustard': {
    'displayName': 'Mustard',
    'description': 'Proteins in mustard seeds and products derived from them.',
    'commonSources':
        'Mustard condiment, mustard powder, curry powder, some salad dressings, Indian cuisine.',
    'reactionType': 'Allergic (IgE-mediated)',
    'severity': 'Mild to Severe',
    'prevalence': 'Particularly prevalent in France and Spain.',
    'avoidanceNote':
        'EU-declared allergen. Can be hidden in spice blends and marinades.',
  },
  'Molluscs': {
    'displayName': 'Molluscs',
    'description':
        'Proteins in squid, octopus, mussels, oysters, clams, and scallops.',
    'commonSources':
        'Oysters, mussels, clams, squid (calamari), octopus, scallops.',
    'reactionType': 'Allergic (IgE-mediated)',
    'severity': 'Moderate to Severe',
    'prevalence': 'Less common than crustacean shellfish allergy but lifelong.',
    'avoidanceNote':
        'EU-declared allergen. Separate from crustacean shellfish allergy; cross-reactivity occurs but not always.',
  },
  'Artificial Colors': {
    'displayName': 'Artificial Colors',
    'description':
        'Synthetic azo dyes and food colorants used to enhance appearance.',
    'commonSources':
        'Confectionery, soft drinks, desserts, cereals, packaged snacks.',
    'reactionType': 'Pseudo-allergic / sensitivity',
    'severity': 'Mild (behavioral effects in children)',
    'prevalence': 'Sensitivity estimated at <1% but under-reported.',
    'avoidanceNote':
        'Look for E numbers 102, 104, 110, 122, 124, 129 on EU labels. These carry hyperactivity warnings.',
  },
};

// ─────────────────────────────────────────────────────────────────────────────
// Health Conditions Dataset
// ─────────────────────────────────────────────────────────────────────────────
const _kHealthConditions = <String, Map<String, dynamic>>{
  'Diabetes': {
    'displayName': 'Diabetes (Type 1 & 2)',
    'description': 'Impaired ability to regulate blood glucose.',
    'dietaryAdvice':
        'Avoid high-sugar and high-glycemic-index foods. Limit refined carbohydrates. Prefer complex carbs, high-fiber foods, and low-GI alternatives.',
    'keyIngredientsToAvoid': [
      'sugar',
      'high fructose corn syrup',
      'maltitol',
      'maple syrup',
    ],
    'saferAlternatives': 'Stevia, sucralose, acesulfame potassium, erythritol.',
  },
  'Lactose Intolerance': {
    'displayName': 'Lactose Intolerance',
    'description':
        'Inability to fully digest lactose due to insufficient lactase enzyme.',
    'dietaryAdvice':
        'Avoid milk and dairy products containing lactose. Fermented dairy (yoghurt, aged cheese) may be better tolerated. Choose lactose-free or plant-based alternatives.',
    'keyIngredientsToAvoid': [
      'milk',
      'milk solids',
      'skim milk',
      'lactose',
      'whey protein',
      'casein',
    ],
    'saferAlternatives': 'Oat milk, almond milk, lactose-free dairy products.',
  },
  'High Blood Pressure': {
    'displayName': 'Hypertension (High Blood Pressure)',
    'description': 'Persistently elevated arterial blood pressure.',
    'dietaryAdvice':
        'Strictly limit sodium intake (<2g/day). Avoid processed meats, canned foods, and salty snacks. Follow the DASH diet: rich in fruits, vegetables, and low-fat dairy.',
    'keyIngredientsToAvoid': ['sodium', 'salt', 'sodium benzoate', 'e211'],
    'saferAlternatives':
        'Potassium-based salt substitutes (consult doctor), herbs and spices for flavoring.',
  },
  'Heart Condition': {
    'displayName': 'Cardiovascular Disease / Heart Conditions',
    'description':
        'Conditions affecting the heart and blood vessels, including coronary artery disease.',
    'dietaryAdvice':
        'Eliminate trans fats completely. Limit saturated fat to <7% of calories. Increase omega-3 fatty acid intake. Choose monounsaturated and polyunsaturated fats.',
    'keyIngredientsToAvoid': [
      'trans fat',
      'partially hydrogenated oil',
      'saturated fat',
      'palm oil',
      'coconut oil',
    ],
    'saferAlternatives':
        'Olive oil, canola oil, avocado oil, omega-3 rich fish oils.',
  },
  'IBS': {
    'displayName': 'Irritable Bowel Syndrome (IBS)',
    'description':
        'Functional gastrointestinal disorder causing cramps, bloating, and altered bowel habits.',
    'dietaryAdvice':
        'Follow the low-FODMAP diet. Avoid fermentable carbohydrates: fructose, lactose, sorbitol, mannitol, fructans, and galactans. Limit caffeine and alcohol.',
    'keyIngredientsToAvoid': [
      'sorbitol',
      'xylitol',
      'maltitol',
      'high fructose corn syrup',
      'inulin',
      'carrageenan',
    ],
    'saferAlternatives':
        'Small amounts of maple syrup (lower fructose), glucose syrup, rice syrup.',
  },
  'Asthma': {
    'displayName': 'Asthma',
    'description':
        'Chronic inflammatory airway disease causing wheezing, breathlessness, and chest tightness.',
    'dietaryAdvice':
        'Avoid sulphites (wine, dried fruits) and food additives known to trigger symptoms. Some asthmatics react to aspirin/NSAIDs-related compounds like benzoates.',
    'keyIngredientsToAvoid': ['sulphites', 'e220', 'sodium benzoate', 'e211'],
    'saferAlternatives':
        'Fresh, unprocessed foods; avoid packaged dried fruits with sulphite preservatives.',
  },
  'Cancer Risk': {
    'displayName': 'Cancer Risk Reduction',
    'description':
        'Dietary measures to minimise exposure to potential carcinogens.',
    'dietaryAdvice':
        'Limit processed meats containing nitrites. Avoid burned or heavily charred foods. Reduce alcohol. Choose organic where feasible to minimise pesticide exposure.',
    'keyIngredientsToAvoid': ['e250', 'e320', 'e321', 'alcohol'],
    'saferAlternatives':
        'Fresh meats without added nitrites, natural antioxidant-rich foods (berries, leafy greens).',
  },
  'Osteoporosis': {
    'displayName': 'Osteoporosis',
    'description': 'Reduced bone density increasing fracture risk.',
    'dietaryAdvice':
        'Ensure adequate calcium and vitamin D intake. Limit phosphoric acid (cola drinks) and excessive sodium, which increase urinary calcium loss. Limit caffeine and alcohol.',
    'keyIngredientsToAvoid': [
      'phosphoric acid',
      'sodium',
      'salt',
      'caffeine',
      'alcohol',
    ],
    'saferAlternatives':
        'Calcium-fortified plant milks, leafy greens, dairy or dairy alternatives with added vitamin D.',
  },
  'Anxiety Disorder': {
    'displayName': 'Anxiety Disorders',
    'description':
        'Persistent excessive worry or fear affecting daily functioning.',
    'dietaryAdvice':
        'Limit or avoid caffeine and alcohol, which can worsen anxiety and disrupt sleep. Avoid high-sugar foods that cause blood glucose crashes. Consider magnesium-rich foods.',
    'keyIngredientsToAvoid': [
      'caffeine',
      'alcohol',
      'sugar',
      'high fructose corn syrup',
    ],
    'saferAlternatives':
        'Herbal teas (chamomile, passionflower), decaffeinated beverages, complex carbohydrates.',
  },
  'Liver Disease': {
    'displayName': 'Liver Disease (including Fatty Liver)',
    'description':
        'Conditions affecting liver function including NAFLD, cirrhosis, and hepatitis.',
    'dietaryAdvice':
        'Avoid alcohol entirely. Reduce fructose and high-fructose corn syrup. Limit saturated fat and ultra-processed foods. Support liver health with antioxidant-rich foods.',
    'keyIngredientsToAvoid': [
      'alcohol',
      'high fructose corn syrup',
      'trans fat',
      'partially hydrogenated oil',
    ],
    'saferAlternatives':
        'Water, herbal teas, fresh fruit juice in moderation, olive oil.',
  },
  'PKU': {
    'displayName': 'Phenylketonuria (PKU)',
    'description':
        'Rare metabolic disorder — inability to metabolize phenylalanine.',
    'dietaryAdvice':
        'Strictly avoid aspartame, which is metabolized to phenylalanine. Follow a very low phenylalanine diet under medical supervision.',
    'keyIngredientsToAvoid': ['aspartame'],
    'saferAlternatives':
        'Stevia, sucralose, acesulfame potassium, saccharin — all phenylalanine-free.',
  },
  'Infant Safety': {
    'displayName': 'Infant Safety (<12 months)',
    'description':
        'Dietary restrictions critical for infants under one year of age.',
    'dietaryAdvice':
        'Do not give honey to infants under 12 months due to botulism risk. Avoid added salt, sugar, and unpasteurised products. Follow age-appropriate feeding guidelines.',
    'keyIngredientsToAvoid': ['honey', 'salt', 'sugar'],
    'saferAlternatives':
        'Age-appropriate purées and infant-specific foods without added salt or sugar.',
  },
};

// ─────────────────────────────────────────────────────────────────────────────
// Safer Alternatives Dataset
// ─────────────────────────────────────────────────────────────────────────────
const _kAlternativesDb = <String, List<Map<String, dynamic>>>{
  'Sweetener': [
    {
      'name': 'Low Sugar Organic Spread',
      'safety': 'Better Choice',
      'reason': 'Significantly reduced sugar content with natural sweeteners',
      'tags': ['Low Sugar', 'Organic'],
    },
    {
      'name': 'Stevia-Sweetened Alternative',
      'safety': 'Highly Safe',
      'reason': 'Zero glycemic impact — uses plant-based stevia sweetener',
      'tags': ['Zero Sugar', 'Plant-Based'],
    },
    {
      'name': 'Date-Sweetened Snack Bar',
      'safety': 'Natural',
      'reason':
          'Sweetened only with whole dates — contains fiber, iron, and potassium',
      'tags': ['Whole Food', 'No Added Sugar'],
    },
    {
      'name': 'Coconut Sugar Biscuits',
      'safety': 'Better Choice',
      'reason':
          'Uses coconut sugar — lower glycemic index than refined white sugar',
      'tags': ['Lower GI', 'Minimally Processed'],
    },
  ],
  'Dairy': [
    {
      'name': 'Vegan Dairy-Free Spread',
      'safety': 'Safer',
      'reason':
          'No dairy ingredients — ideal for lactose intolerance and dairy allergy',
      'tags': ['Dairy-Free', 'Vegan'],
    },
    {
      'name': 'Oat Milk Alternative',
      'safety': 'Plant-Based',
      'reason': 'Made from oats — free from dairy proteins and lactose',
      'tags': ['Oat-Based', 'Vegan'],
    },
    {
      'name': 'Almond Milk Yoghurt',
      'safety': 'Plant-Based',
      'reason':
          'Completely dairy-free — made from almonds with live probiotic cultures',
      'tags': ['Dairy-Free', 'Probiotic', 'Vegan'],
    },
    {
      'name': 'Coconut Milk Ice Cream',
      'safety': 'Dairy-Free',
      'reason': 'Creamy coconut base — no milk proteins or lactose',
      'tags': ['Dairy-Free', 'Vegan'],
    },
    {
      'name': 'Lactose-Free Milk',
      'safety': 'Tolerable',
      'reason': 'Same dairy nutritional profile with lactase enzyme pre-added',
      'tags': ['Lactose-Free', 'Dairy'],
    },
  ],
  'Allergen': [
    {
      'name': 'Gluten-Free Certified Alternative',
      'safety': 'Safe for Celiac',
      'reason':
          'Certified gluten-free — safe for celiac disease and wheat allergy',
      'tags': ['Gluten-Free', 'Certified'],
    },
    {
      'name': 'Nut-Free Organic Option',
      'safety': 'Allergen Safe',
      'reason': 'Produced in a dedicated nut-free facility',
      'tags': ['Nut-Free', 'Allergen-Safe'],
    },
    {
      'name': 'Egg-Free Vegan Mayo',
      'safety': 'Allergen Safe',
      'reason': 'No egg — made from aquafaba or sunflower oil emulsion',
      'tags': ['Egg-Free', 'Vegan'],
    },
    {
      'name': 'Soy-Free Protein Powder',
      'safety': 'Allergen Safe',
      'reason': 'Pea or rice protein — completely free from soy and dairy',
      'tags': ['Soy-Free', 'Dairy-Free', 'Plant-Based'],
    },
    {
      'name': 'Multi-Allergen-Free Cereal',
      'safety': 'Highly Safe',
      'reason':
          'Free from top 9 allergens — certified in a dedicated allergen-free facility',
      'tags': ['Top-9-Free', 'Certified', 'Clean Label'],
    },
  ],
  'Fat': [
    {
      'name': 'Heart-Healthy Olive Oil Spread',
      'safety': 'Heart Safe',
      'reason': 'No trans fats — high in monounsaturated healthy fats',
      'tags': ['Heart-Safe', 'No Trans Fat'],
    },
    {
      'name': 'Avocado Oil Blend',
      'safety': 'Clean Label',
      'reason': 'Rich in oleic acid — promotes healthy cholesterol levels',
      'tags': ['Clean Label', 'Heart-Healthy'],
    },
    {
      'name': 'Rapeseed (Canola) Oil Spray',
      'safety': 'Heart Safe',
      'reason': 'Very low in saturated fat; excellent omega-3 to omega-6 ratio',
      'tags': ['Low Saturated Fat', 'Heart-Healthy'],
    },
    {
      'name': 'Flaxseed Enriched Spread',
      'safety': 'Heart Safe',
      'reason': 'Enriched with ALA omega-3 — supports cardiovascular health',
      'tags': ['Omega-3', 'No Trans Fat'],
    },
  ],
  'Additive': [
    {
      'name': 'Organic Clean-Label Spread',
      'safety': 'Highly Safe',
      'reason': 'No artificial additives, MSG, or flavor enhancers',
      'tags': ['No Additives', 'Organic'],
    },
    {
      'name': 'No-Additive Dried Fruit Mix',
      'safety': 'Natural',
      'reason': 'Dried without sulphites or preservatives — just whole fruit',
      'tags': ['Additive-Free', 'Natural'],
    },
    {
      'name': 'Clean Label Tomato Sauce',
      'safety': 'Clean Label',
      'reason': 'No artificial flavors, colors, or MSG — naturally flavored',
      'tags': ['No MSG', 'Clean Label', 'Natural'],
    },
  ],
  'Colorant': [
    {
      'name': 'Natural Color Organic Product',
      'safety': 'Natural',
      'reason': 'Uses only plant-derived natural colorants — no synthetic dyes',
      'tags': ['Natural Colors', 'No Artificial Dyes'],
    },
    {
      'name': 'Beetroot-Colored Sweets',
      'safety': 'Natural',
      'reason':
          'Colored with beetroot extract — no azo dyes or artificial colorants',
      'tags': ['Natural Colors', 'No E-Numbers'],
    },
    {
      'name': 'Turmeric-Colored Snack',
      'safety': 'Natural',
      'reason':
          'Golden color from turmeric — a natural anti-inflammatory colorant',
      'tags': ['Natural Colors', 'Anti-Inflammatory'],
    },
  ],
  'Preservative': [
    {
      'name': 'Preservative-Free Organic Spread',
      'safety': 'Clean Label',
      'reason':
          'No chemical preservatives — naturally preserved or vacuum packed',
      'tags': ['Preservative-Free', 'Clean Label'],
    },
    {
      'name': 'Vacuum-Packed Sliced Meats',
      'safety': 'No Nitrites',
      'reason':
          'No sodium nitrite — preserved by vacuum sealing and refrigeration',
      'tags': ['Nitrite-Free', 'Clean Label'],
    },
    {
      'name': 'Naturally Preserved Jam',
      'safety': 'Clean Label',
      'reason':
          'High fruit content and low pH preserve naturally — no benzoates or sorbates',
      'tags': ['Preservative-Free', 'High Fruit', 'Natural'],
    },
  ],
  'Grain': [
    {
      'name': 'Certified Gluten-Free Pasta',
      'safety': 'Safe for Celiac',
      'reason': 'Made from brown rice or quinoa — certified <20 ppm gluten',
      'tags': ['Gluten-Free', 'Certified'],
    },
    {
      'name': 'Buckwheat Bread',
      'safety': 'Gluten-Free',
      'reason':
          'Buckwheat is naturally gluten-free — higher in protein and minerals than wheat',
      'tags': ['Gluten-Free', 'High Protein', 'Natural'],
    },
    {
      'name': 'Quinoa Flakes Cereal',
      'safety': 'Gluten-Free',
      'reason':
          'Complete protein, gluten-free grain — safe for celiac and wheat allergy',
      'tags': ['Gluten-Free', 'Complete Protein'],
    },
  ],
  'Stimulant': [
    {
      'name': 'Decaffeinated Coffee Blend',
      'safety': 'Caffeine-Free',
      'reason':
          'Virtually no caffeine — suitable for anxiety, pregnancy, and sleep disorders',
      'tags': ['Caffeine-Free', 'Decaf'],
    },
    {
      'name': 'Herbal Chamomile Tea',
      'safety': 'Highly Safe',
      'reason': 'Naturally caffeine-free with calming properties',
      'tags': ['Caffeine-Free', 'Calming', 'Natural'],
    },
    {
      'name': 'Chicory Root Drink',
      'safety': 'Highly Safe',
      'reason': 'Coffee-like flavor, zero caffeine, rich in prebiotic inulin',
      'tags': ['Caffeine-Free', 'Prebiotic'],
    },
  ],
  'Protein': [
    {
      'name': 'Pea Protein Dairy-Free Shake',
      'safety': 'Highly Safe',
      'reason':
          'No dairy, soy, or eggs — complete amino acid profile from peas',
      'tags': ['Dairy-Free', 'Soy-Free', 'Plant-Based'],
    },
    {
      'name': 'Hemp Seed Protein Powder',
      'safety': 'Natural',
      'reason':
          'Naturally complete protein, dairy and soy free, rich in omega-3',
      'tags': ['Dairy-Free', 'Omega-3', 'Clean Label'],
    },
  ],
};

/// Alternative product model
class AlternativeProduct {
  final String name;
  final String safety;
  final String reason;
  final List<String> tags;

  const AlternativeProduct({
    required this.name,
    required this.safety,
    required this.reason,
    required this.tags,
  });

  factory AlternativeProduct.fromMap(Map<String, dynamic> map) {
    return AlternativeProduct(
      name: map['name'] as String,
      safety: map['safety'] as String,
      reason: map['reason'] as String,
      tags: List<String>.from(map['tags'] as List),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'safety': safety,
    'reason': reason,
    'tags': tags,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// IngredientDataService
// ─────────────────────────────────────────────────────────────────────────────

class IngredientDataService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Seed Firestore ──────────────────────────────────────────────────────────

  /// Seeds ingredients and alternatives to Firestore.
  /// Safe to call multiple times (uses set with merge).
  static Future<void> seedFirestore() async {
    try {
      debugPrint('[IngredientDataService] Starting Firestore seed...');
      final batch = _db.batch();

      // Seed ingredients
      for (final entry in _kLocalIngredients.entries) {
        final ref = _db
            .collection('ingredients')
            .doc(entry.key.replaceAll(' ', '_'));
        batch.set(ref, {
          'normalized_name': entry.key,
          ...entry.value,
          'seeded_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      await batch.commit();
      debugPrint(
        '[IngredientDataService] Ingredients seeded (${_kLocalIngredients.length} items).',
      );

      // Seed alternatives (separate batch)
      final altBatch = _db.batch();
      for (final entry in _kAlternativesDb.entries) {
        for (int i = 0; i < entry.value.length; i++) {
          final ref = _db.collection('alternatives').doc('${entry.key}_$i');
          altBatch.set(ref, {
            'category': entry.key,
            ...entry.value[i],
            'seeded_at': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      }

      await altBatch.commit();
      debugPrint('[IngredientDataService] Alternatives seeded.');
    } catch (e) {
      debugPrint('[IngredientDataService] Seed error: $e');
    }
  }

  // ── Ingredient Lookup ───────────────────────────────────────────────────────

  /// Returns ingredient data from Firestore, falling back to local dataset.
  static Future<Map<String, dynamic>?> lookupIngredient(
    String normalizedKey,
  ) async {
    // 1. Try local first (fast, offline-safe)
    if (_kLocalIngredients.containsKey(normalizedKey)) {
      return _kLocalIngredients[normalizedKey];
    }

    // 2. Try Firestore
    try {
      final snap = await _db
          .collection('ingredients')
          .where('normalized_name', isEqualTo: normalizedKey)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) return snap.docs.first.data();
    } catch (e) {
      debugPrint('[IngredientDataService] Firestore lookup failed: $e');
    }

    return null;
  }

  // ── Parse text → IngredientModel list ──────────────────────────────────────

  /// Scans OCR text against the full ingredient database and returns matches.
  static Future<List<IngredientModel>> parseIngredientsFromText(
    String text,
  ) async {
    final results = <IngredientModel>[];
    final lower = text.toLowerCase();

    // Sort keys by length descending so multi-word phrases match first
    final sortedKeys = _kLocalIngredients.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final key in sortedKeys) {
      if (lower.contains(key)) {
        final data = _kLocalIngredients[key]!;
        results.add(_buildModel(key, data));
      }
    }

    // Firestore supplementary lookup for unknown tokens
    if (results.isEmpty && text.isNotEmpty) {
      try {
        final tokens = lower
            .split(RegExp(r'[,;\n\r]'))
            .map((t) => t.trim())
            .where((t) => t.length > 2)
            .take(20)
            .toList();

        for (final token in tokens) {
          final data = await lookupIngredient(token);
          if (data != null) {
            results.add(_buildModel(token, data));
          }
        }
      } catch (e) {
        debugPrint('[IngredientDataService] Supplementary lookup failed: $e');
      }
    }

    // Generic fallback
    if (results.isEmpty && text.isNotEmpty) {
      results.add(
        IngredientModel(
          name: 'Unknown Ingredients',
          riskLevel: 'Caution',
          description:
              'Could not identify individual ingredients from the label.',
          detailedExplanation:
              'The OCR scan captured text but could not match any known ingredients. Try scanning in better lighting or from a clearer angle.',
          userImpact:
              'No personalized risk assessment possible for unrecognized ingredients.',
          regulatoryNote:
              'Always consult the original product label for accurate ingredient information.',
        ),
      );
    }

    return results;
  }

  // ── Alternatives Lookup ─────────────────────────────────────────────────────

  /// Returns safer alternatives based on ingredient categories detected in the scan.
  static Future<List<AlternativeProduct>> getAlternatives(
    List<IngredientModel> ingredients,
  ) async {
    final results = <AlternativeProduct>[];
    final addedNames = <String>{};

    // Determine which categories are in the ingredient list
    final categories = <String>{};
    for (final ing in ingredients) {
      if (ing.riskLevel == 'Safe') continue;
      final cat = _getCategoryForIngredient(ing.name.toLowerCase());
      if (cat != null) categories.add(cat);
    }

    // 1. Try Firestore alternatives first
    try {
      for (final category in categories) {
        final snap = await _db
            .collection('alternatives')
            .where('category', isEqualTo: category)
            .limit(2)
            .get();

        for (final doc in snap.docs) {
          final alt = AlternativeProduct.fromMap(doc.data());
          if (!addedNames.contains(alt.name)) {
            results.add(alt);
            addedNames.add(alt.name);
          }
        }
      }
    } catch (e) {
      debugPrint(
        '[IngredientDataService] Alternatives Firestore query failed: $e',
      );
    }

    // 2. Fill from local dataset if Firestore returned nothing
    if (results.isEmpty) {
      for (final category in categories) {
        final localAlts = _kAlternativesDb[category] ?? [];
        for (final altMap in localAlts) {
          final alt = AlternativeProduct.fromMap(altMap);
          if (!addedNames.contains(alt.name)) {
            results.add(alt);
            addedNames.add(alt.name);
          }
        }
      }
    }

    // 3. Generic fallback
    if (results.isEmpty) {
      results.add(
        const AlternativeProduct(
          name: 'Natural Ingredient Product',
          safety: 'Safe',
          reason:
              'Minimal processed ingredients — clean label with no harmful additives',
          tags: ['Clean Label', 'Natural'],
        ),
      );
    }

    return results;
  }

  // ── Demo Scan Dataset ───────────────────────────────────────────────────────

  /// Returns a rich demo scan ScanResult-like dataset for testing all features.
  static List<IngredientModel> getDemoIngredients() {
    final demoKeys = [
      'sugar',
      'high fructose corn syrup',
      'milk solids',
      'wheat flour',
      'palm oil',
      'sodium benzoate',
      'artificial color',
      'cocoa powder',
      'lecithin',
      'vitamin c',
    ];

    return demoKeys.map((key) {
      final data = _kLocalIngredients[key]!;
      return _buildModel(key, data);
    }).toList();
  }

  // ── Private Helpers ─────────────────────────────────────────────────────────

  static IngredientModel _buildModel(String key, Map<String, dynamic> data) {
    final allergen = data['allergenKey'] as String?;
    final condition = data['conditionKey'] as String?;
    String userImpact;
    if (allergen != null && condition != null) {
      userImpact = 'Relevant if you have a $allergen allergy or $condition.';
    } else if (allergen != null) {
      userImpact = 'Relevant if you have a $allergen allergy.';
    } else if (condition != null) {
      userImpact = 'Relevant if you have $condition.';
    } else {
      userImpact =
          'Check with your healthcare provider if you have specific dietary restrictions.';
    }

    return IngredientModel(
      name: _capitalize(key),
      riskLevel: data['risk'] as String,
      description: data['description'] as String,
      detailedExplanation: data['explanation'] as String,
      userImpact: userImpact,
      regulatoryNote: data['regulatory'] as String,
      allergenKey: allergen,
      conditionKey: condition,
    );
  }

  static String? _getCategoryForIngredient(String name) {
    for (final entry in _kLocalIngredients.entries) {
      if (name.contains(entry.key) || entry.key.contains(name)) {
        return entry.value['category'] as String?;
      }
    }
    return null;
  }

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w)
        .join(' ');
  }
}
