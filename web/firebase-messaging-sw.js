importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyANa50T_GpAVXx4SQEsnU52aO72Ma529_I",
  authDomain: "flashai-99601.firebaseapp.com",
  projectId: "flashai-99601",
  storageBucket: "flashai-99601.firebasestorage.app",
  messagingSenderId: "293388346215",
  appId: "1:293388346215:web:5853aad1fd46dd635185c2",
  measurementId: "G-RSFT3MV2VE"
});

const messaging = firebase.messaging();
