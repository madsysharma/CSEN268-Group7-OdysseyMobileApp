
// const {onCall} = require("firebase-functions/v2/https");
// const {onDocumentWritten} = require("firebase-functions/v2/firestore");
const functions = require("firebase-functions/v2");
const admin = require("firebase-admin");
const axios = require("axios");
const {SecretManagerServiceClient} = require("@google-cloud/secret-manager");
const secretClient = new SecretManagerServiceClient();
admin.initializeApp();


/**
 * Retrieves a secret value from Google Cloud Secret Manager.
 *
 * @param {string} secretName - The name of the secret to retrieve.
 * @return {Promise<string>} - The secret value as a string.
 * @throws {Error} - If the secret cannot be retrieved.
 */
async function getSecret(secretName) {
  try {
    const [accessResponse] = await secretClient.accessSecretVersion({
      name: `projects/749175602340/secrets/${secretName}/versions/latest`,
    });
    return accessResponse.payload.data.toString("utf8");
  } catch (error) {
    console.error(`Failed to access secret ${secretName}:`, error.message);
    throw new Error(`Unable to retrieve secret ${secretName}`);
  }
}

exports.sendFriendRequestEmail = functions.https.onCall(async (data, context) => {
  const mailgunDomain = await getSecret("mailgun-domain");
  const mailgunApiKey = await getSecret("mailgun-api-key");
  console.log("Function triggered");
  console.log("Raw data received (full object):", data);

  try {
    if (!data) {
      console.error("No data received.");
      throw new functions.https.HttpsError(
          "invalid-argument",
          "The function must be called with a valid payload.",
      );
    }
    const email = data.data.email;
    const senderName = data.data.senderName;
    const senderEmail = data.data.senderEmail;
    console.log("Email: ", email);
    console.log("Sender name: ", senderName);
    console.log("Sender email: ", senderEmail);

    console.log("Validated data:", {email, senderName, senderEmail});

    const mailData = {
      from: "noreply@***REMOVED***",
      to: email,
      subject: `You have a new friend request!`,
      text: `${senderName} wants to connect with you on Odyssey! Make a new friend today!`,
    };
    const response = await axios.post(
        `https://api.mailgun.net/v3/${mailgunDomain}/messages`,
        mailData,
        {
          auth: {username: "api", password: mailgunApiKey},
          headers: {
            "Content-Type": "application/x-www-form-urlencoded",
          },
        },
    );
    return {
      success: true,
      data: response.data,
      message: "Email sent successfully!",
    };
  } catch (error) {
    console.error("Error in sendFriendRequestEmail function:", error.message);
    throw new functions.https.HttpsError("internal", error.message || "Unknown error occurred.");
  }
});

exports.sendAcceptRequestEmail = functions.https.onCall(async (data, context) => {
  const mailgunDomain = "***REMOVED***";
  const mailgunApiKey = await getSecret("mailgun-api-key");
  console.log("Function triggered");
  console.log("Raw data received (full object):", data);
  if (!data) {
    console.error("No data received.");
    throw new functions.https.HttpsError(
        "invalid-argument",
        "The function must be called with a valid payload.",
    );
  }

  const email = data.data.email;
  const senderName = data.data.senderName;
  const senderEmail = data.data.senderEmail;
  console.log("Email: ", email);
  console.log("Sender name: ", senderName);
  console.log("Sender email: ", senderEmail);
  console.log("Validated data:", {email, senderName, senderEmail});
  try {
    const mailData = {
      from: "noreply@***REMOVED***",
      to: email,
      subject: `Your friend request has been accepted!`,
      text: `${senderName} accepted your friend request.`,
    };
    const response = await axios.post(
        `https://api.mailgun.net/v3/${mailgunDomain}/messages`,
        mailData,
        {
          auth: {username: "api", password: mailgunApiKey},
          headers: {
            "Content-Type": "application/x-www-form-urlencoded",
          },
        },
    );
    return {
      success: true,
      data: response.data,
      message: "Email sent successfully!",
    };
  } catch (error) {
    console.error("Error sending email:", error.toString());

    return {
      success: false,
      message: "Failed to send email. Please try again later.",
    };
  }
});
