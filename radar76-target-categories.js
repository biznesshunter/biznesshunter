const fs=require("fs");
const cats=JSON.parse(fs.readFileSync("./radar76_allovoisins_categories.json","utf8"));

const terms=/remorque|nettoyeur|karcher|débrouss|scarif|taille.?haie|fendeur|shampouineuse|tente|promenade|ménage|menage|chien|chat|jardin|entretien|matériel|materiel/i;

const found=cats.filter(x=>terms.test(x.name));

console.log("CATEGORIES PERTINENTES:",found.length);
console.log(JSON.stringify(found,null,2));
