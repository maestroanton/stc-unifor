// functions/index.js - Firebase Cloud Functions
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { setGlobalOptions } = require("firebase-functions/v2");
const admin = require("firebase-admin");

setGlobalOptions({
  region: "us-central1",
  timeoutSeconds: 540,
  memory: "512MiB"
});

admin.initializeApp();

let axios;
let moment;

function getAxios() {
  if (!axios) {
    axios = require("axios");
  }
  return axios;
}

function getMoment() {
  if (!moment) {
    moment = require("moment");
  }
  return moment;
}

exports.cleanupAuditLogs = onSchedule({
  schedule: "0 2 * * 0",
  timeZone: "America/Fortaleza"
}, async (event) => {
  console.log("Starting scheduled audit log cleanup...");

  try {
    const db = admin.firestore();
    const oneYearAgo = new Date();
    oneYearAgo.setFullYear(oneYearAgo.getFullYear() - 1);

    let totalDeleted = 0;
    let batch = db.batch();
    let batchSize = 0;

    let hasMoreDocs = true;
    while (hasMoreDocs) {
      const query = db.collection("audit_logs")
          .where(
              "timestamp",
              "<",
              admin.firestore.Timestamp.fromDate(oneYearAgo),
          )
          .limit(500);

      const snapshot = await query.get();

      if (snapshot.empty) {
        hasMoreDocs = false;
        break;
      }

      for (const doc of snapshot.docs) {
        batch.delete(doc.ref);
        batchSize++;

        if (batchSize >= 500) {
          break;
        }
      }

      if (batchSize > 0) {
        await batch.commit();
        totalDeleted += batchSize;
        console.log(`Deleted ${batchSize} audit logs (batch)`);

        batch = db.batch();
        batchSize = 0;
      }

      if (snapshot.docs.length < 500) {
        hasMoreDocs = false;
      }
    }

    const logEntry = {
      userId: "system",
      userEmail: "system@gistc.com",
      userDisplayName: "Sistema Automático",
      uf: "SYSTEM",
      isAdmin: true,
      action: "delete",
      module: "system",
      description:
          "Limpeza automática de logs de auditoria " +
          "(Cloud Function)",
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      metadata: {
        cleanup_type: "scheduled_cloud_function",
        records_deleted: totalDeleted,
        days_kept: 365,
        cleanup_date: new Date().toISOString(),
      },
    };
    await db.collection("audit_logs").add(logEntry);

    console.log(`Audit log cleanup completed: ${totalDeleted} records removed`);
    return null;
  } catch (error) {
    console.error("Error during audit log cleanup:", error);

    try {
      const errorLog = {
        userId: "system",
        userEmail: "system@gistc.com",
        userDisplayName: "Sistema Automático",
        uf: "SYSTEM",
        isAdmin: true,
        action: "delete",
        module: "system",
        description:
            "Erro na limpeza automática de logs de auditoria",
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        metadata: {
          cleanup_type: "scheduled_cloud_function",
          error: error.message,
        },
      };
      await admin.firestore().collection("audit_logs").add(errorLog);
    } catch (logError) {
      console.error("Could not log cleanup error:", logError);
    }

    throw error;
  }
});

// EmailJS configuration for licenses
const LICENSE_EMAIL_CONFIG = {
  serviceId: 'service_gkr2xu7',
  templateIdWarning: 'template_license_warning',
  templateIdExpired: 'template_ydzo3gj',
  publicKey: 'IbAJxit6WycaHDf2W',
  emailJsUrl: 'https://api.emailjs.com/api/v1.0/email/send',
  recipientEmail: 'antongmsob@gmail.com',
  fromEmail: 'glasseredita@outlook.com'
};

// Helper function to send emails
async function sendEmail(templateParams, templateId, config) {
  try {
    const axios = getAxios();
    const requestBody = {
      service_id: config.serviceId,
      template_id: templateId,
      user_id: config.publicKey,
      template_params: templateParams,
    };

    const response = await axios.post(config.emailJsUrl, requestBody, {
      headers: { 'Content-Type': 'application/json' }
    });

    if (response.status === 200) {
      console.log(`Email sent successfully with template: ${templateId}`);
      return true;
    } else {
      console.error(`Failed to send email: ${response.status} - ${response.data}`);
      return false;
    }
  } catch (e) {
    console.error('Error sending email:', e);
    return false;
  }
}

// Manual cleanup function that can be called via HTTP
exports.manualCleanupAuditLogs = onCall(async (request) => {
  // Check if user is authenticated and is admin
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  const daysToKeep = request.data.daysToKeep || 365;
  const message = `Starting manual audit log cleanup (${daysToKeep} days retention)...`;
  console.log(message);

  try {
    const db = admin.firestore();
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - daysToKeep);

    let totalDeleted = 0;
    let batch = db.batch();
    let batchSize = 0;

    let hasMoreDocs = true;
    while (hasMoreDocs) {
      const query = db.collection("audit_logs")
          .where(
              "timestamp",
              "<",
              admin.firestore.Timestamp.fromDate(cutoffDate),
          )
          .limit(500);

      const snapshot = await query.get();

      if (snapshot.empty) {
        hasMoreDocs = false;
        break;
      }

      for (const doc of snapshot.docs) {
        batch.delete(doc.ref);
        batchSize++;

        if (batchSize >= 500) {
          break;
        }
      }

      if (batchSize > 0) {
        await batch.commit();
        totalDeleted += batchSize;
        console.log(`Deleted ${batchSize} audit logs (manual batch)`);

        batch = db.batch();
        batchSize = 0;
      }

      if (snapshot.docs.length < 500) {
        hasMoreDocs = false;
      }
    }

    // Log the manual cleanup
    const logEntry = {
      userId: request.auth.uid,
      userEmail: request.auth.token.email,
      userDisplayName: request.auth.token.name || "Admin",
      uf: "MANUAL",
      isAdmin: true,
      action: "delete",
      module: "system",
      description:
          "Limpeza manual de logs de auditoria " +
          "(Cloud Function)",
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      metadata: {
        cleanup_type: "manual_cloud_function",
        records_deleted: totalDeleted,
        days_kept: daysToKeep,
        cleanup_date: new Date().toISOString(),
      },
    };
    await db.collection("audit_logs").add(logEntry);

    return {
      success: true,
      deletedCount: totalDeleted,
      daysKept: daysToKeep,
    };
  } catch (error) {
    console.error("Error during manual audit log cleanup:", error);
    throw new HttpsError("internal", "Cleanup failed", error.message);
  }
});

// Helper function to check if license is within days of expiring
function isWithinDaysOfExpiring(license, days) {
  if (!license.dataVencimento) return false;

  try {
    const moment = getMoment();
    const parts = license.dataVencimento.split('-');
    if (parts.length !== 3) return false;

    const day = Number.parseInt(parts[0]);
    const month = Number.parseInt(parts[1]);
    const year = Number.parseInt(parts[2]);

    const vencimento = moment([year, month - 1, day]); // month is 0-indexed in moment
    const now = moment();
    const daysUntilExpiry = vencimento.diff(now, 'days');

    return daysUntilExpiry <= days && daysUntilExpiry > 0;
  } catch (e) {
    console.error(`Error parsing date for License ${license.id}:`, e);
    return false;
  }
}

// Helper function to check if license is expired
function isExpired(license) {
  if (license.status === 'vencida') return true;
  if (!license.dataVencimento) return false;

  try {
    const moment = getMoment();
    const parts = license.dataVencimento.split('-');
    if (parts.length !== 3) return false;

    const day = Number.parseInt(parts[0]);
    const month = Number.parseInt(parts[1]);
    const year = Number.parseInt(parts[2]);

    const vencimento = moment([year, month - 1, day]);
    const now = moment();
    return now.isAfter(vencimento);
  } catch (e) {
    console.error(`Erro decodificando ddos da licença ${license.id}:`, e);
    return false;
  }
}

// Helper function to get remaining days until expiry
function getLicenseRemainingDays(license) {
  if (!license.dataVencimento) return 0;

  try {
    const moment = getMoment();
    const parts = license.dataVencimento.split('-');
    if (parts.length !== 3) return 0;

    const day = Number.parseInt(parts[0]);
    const month = Number.parseInt(parts[1]);
    const year = Number.parseInt(parts[2]);

    const vencimento = moment([year, month - 1, day]);
    const now = moment();
    return vencimento.diff(now, 'days');
  } catch (e) {
    console.error(`Error parsing date for License ${license.id}:`, e);
    return 0;
  }
}

// Scheduled function for license warning emails (runs daily at 10:00 AM)
exports.sendLicenseWarningEmails = onSchedule({
  schedule: "0 10 * * *",
  timeZone: "America/Fortaleza"
}, async (event) => {
  console.log("Starting scheduled license warning email check...");

  try {
    const db = admin.firestore();
    const moment = getMoment();
    const now = moment();

    // Check if emails were already sent today (using timestamp instead of date field)
    const startOfDay = moment().startOf('day').toDate();
    const endOfDay = moment().endOf('day').toDate();
    
    const emailLogQuery = await db.collection("email_logs")
        .where("type", "==", "licenseWarning")
        .where("timestamp", ">=", admin.firestore.Timestamp.fromDate(startOfDay))
        .where("timestamp", "<=", admin.firestore.Timestamp.fromDate(endOfDay))
        .where("metadata.scheduled", "==", true)
        .limit(1)
        .get();

    if (!emailLogQuery.empty) {
      console.log("License warning emails already sent today");
      return null;
    }

    // Get all licenses
    const licensesSnapshot = await db.collection("licenses").get();
    const allLicenses = licensesSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));

    // Filter licenses within 30 days of expiring
    const warningLicenses = allLicenses.filter(license =>
      isWithinDaysOfExpiring(license, 30)
    );

    if (warningLicenses.length === 0) {
      console.log("No licenses within 30 days of expiring");
      return null;
    }

    // Create warning licenses list
    const licensesList = warningLicenses.map(license => {
      const remainingDays = getLicenseRemainingDays(license);
      const statusText = remainingDays > 0 ?
        `Vence em ${remainingDays} dias` :
        `Venceu há ${-remainingDays} dias`;
      return `${license.nome} - UF: ${license.uf} (${statusText})`;
    }).join('\n');

    // Prepare email template parameters
    const pluralSuffix = warningLicenses.length > 1 ? 's' : '';
    const templateParams = {
      from_name: 'Sistema de Licenças GISTC',
      to_email: LICENSE_EMAIL_CONFIG.recipientEmail,
      from_email: LICENSE_EMAIL_CONFIG.fromEmail,
      subject: `Aviso: ${warningLicenses.length} licença${pluralSuffix} próxima${pluralSuffix} do vencimento`,
      total_count: warningLicenses.length.toString(),
      licenses_list: licensesList,
      current_date: now.format('DD/MM/YYYY HH:mm'),
    };

    // Send email
    const success = await sendEmail(templateParams, LICENSE_EMAIL_CONFIG.templateIdWarning, LICENSE_EMAIL_CONFIG);

    // Log email activity
    const logEntry = {
      type: 'licenseWarning',
      status: success ? 'sent' : 'failed',
      recipientEmail: LICENSE_EMAIL_CONFIG.recipientEmail,
      subject: templateParams.subject,
      licenseCount: warningLicenses.length,
      licenseIds: warningLicenses.map(l => l.id),
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      errorMessage: success ? null : 'Falha ao enviar email via EmailJS',
      metadata: {
        module: 'licenses',
        template_id: LICENSE_EMAIL_CONFIG.templateIdWarning,
        days_threshold: 30,
        scheduled: true
      },
    };
    await db.collection("email_logs").add(logEntry);

    const message = `License warning emails sent: ${warningLicenses.length} notifications`;
    console.log(message);
    return null;

  } catch (error) {
    console.error("Error during license warning email check:", error);

    try {
      const errorLog = {
        type: 'licenseWarning',
        status: 'failed',
        recipientEmail: LICENSE_EMAIL_CONFIG.recipientEmail,
        subject: 'Erro ao enviar emails de aviso de licenças',
        licenseCount: 0,
        licenseIds: [],
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        errorMessage: error.message,
        metadata: {
          module: 'licenses',
          template_id: LICENSE_EMAIL_CONFIG.templateIdWarning,
          days_threshold: 30,
          scheduled: true,
          error: error.stack
        },
      };
      await admin.firestore().collection("email_logs").add(errorLog);
    } catch (logError) {
      console.error("Could not log license warning email error:", logError);
    }

    throw error;
  }
});

// Scheduled function for license expired emails (runs daily at 10:30 AM)
exports.sendLicenseExpiredEmails = onSchedule({
  schedule: "30 10 * * *",
  timeZone: "America/Fortaleza"
}, async (event) => {
  console.log("Starting scheduled license expired email check...");

  try {
    const db = admin.firestore();
    const moment = getMoment();
    const now = moment();

    // Check if emails were already sent today (using timestamp instead of date field)
    const startOfDay = moment().startOf('day').toDate();
    const endOfDay = moment().endOf('day').toDate();
    
    const emailLogQuery = await db.collection("email_logs")
        .where("type", "==", "licenseExpired")
        .where("timestamp", ">=", admin.firestore.Timestamp.fromDate(startOfDay))
        .where("timestamp", "<=", admin.firestore.Timestamp.fromDate(endOfDay))
        .where("metadata.scheduled", "==", true)
        .limit(1)
        .get();

    if (!emailLogQuery.empty) {
      console.log("License expired emails already sent today");
      return null;
    }

    // Get all licenses
    const licensesSnapshot = await db.collection("licenses").get();
    const allLicenses = licensesSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));

    // Filter expired licenses
    const expiredLicenses = allLicenses.filter(license => isExpired(license));

    if (expiredLicenses.length === 0) {
      console.log("No expired licenses found");
      return null;
    }

    // Calculate max days expired
    const maxDaysExpired = Math.max(...expiredLicenses.map(license =>
      -getLicenseRemainingDays(license)
    ));

    // Create expired licenses list
    const licensesList = expiredLicenses.map(license => {
      const daysExpired = -getLicenseRemainingDays(license);
      const statusText = `Expirada há ${daysExpired} dias`;
      return `${license.nome} - UF: ${license.uf} (${statusText})`;
    }).join('\n');

    // Prepare email template parameters
    const templateParams = {
      from_name: 'Sistema de Licenças GISTC',
      to_email: LICENSE_EMAIL_CONFIG.recipientEmail,
      from_email: LICENSE_EMAIL_CONFIG.fromEmail,
      subject: `URGENTE: ${expiredLicenses.length} licença${expiredLicenses.length > 1 ? 's' : ''} vencida${expiredLicenses.length > 1 ? 's' : ''}`,
      total_count: expiredLicenses.length.toString(),
      max_days_expired: maxDaysExpired.toString(),
      licenses_list: licensesList,
      current_date: now.format('DD/MM/YYYY HH:mm'),
    };

    // Send email
    const success = await sendEmail(templateParams, LICENSE_EMAIL_CONFIG.templateIdExpired, LICENSE_EMAIL_CONFIG);

    // Log email activity
    const logEntry = {
      type: 'licenseExpired',
      status: success ? 'sent' : 'failed',
      recipientEmail: LICENSE_EMAIL_CONFIG.recipientEmail,
      subject: templateParams.subject,
      licenseCount: expiredLicenses.length,
      licenseIds: expiredLicenses.map(l => l.id),
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      errorMessage: success ? null : 'Falha ao enviar email via EmailJS',
      metadata: {
        module: 'licenses',
        template_id: LICENSE_EMAIL_CONFIG.templateIdExpired,
        max_days_expired: maxDaysExpired,
        scheduled: true
      },
    };
    await db.collection("email_logs").add(logEntry);

    const message = `License expired emails sent: ${expiredLicenses.length} notifications`;
    console.log(message);
    return null;

  } catch (error) {
    console.error("Error during license expired email check:", error);

    try {
      const errorLog = {
        type: 'licenseExpired',
        status: 'failed',
        recipientEmail: LICENSE_EMAIL_CONFIG.recipientEmail,
        subject: 'Erro ao enviar emails de licenças expiradas',
        licenseCount: 0,
        licenseIds: [],
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        errorMessage: error.message,
        metadata: {
          module: 'licenses',
          template_id: LICENSE_EMAIL_CONFIG.templateIdExpired,
          max_days_expired: 0,
          scheduled: true,
          error: error.stack
        },
      };
      await admin.firestore().collection("email_logs").add(errorLog);
    } catch (logError) {
      console.error("Could not log license expired email error:", logError);
    }

    throw error;
  }
});
