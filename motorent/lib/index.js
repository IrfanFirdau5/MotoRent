// Update all vehicles to have the new fields
const { onDocumentUpdated } = require("firebase-functions/v2/firestore");

exports.myUpdateFunction = onDocumentUpdated("collection/{docId}", (event) => {
const admin = require('firebase-admin');
admin.initializeApp();
const db = admin.firestore();

async function addMaintenanceFields() {
  const vehiclesRef = db.collection('vehicles');
  const snapshot = await vehiclesRef.get();
  
  const batch = db.batch();
  snapshot.forEach(doc => {
    batch.update(doc.ref, {
      monthly_maintenance: 0.0,
      monthly_payment: 0.0
    });
  });
  
  await batch.commit();
  console.log('✅ Updated all vehicles with maintenance fields');
}

addMaintenanceFields(); });