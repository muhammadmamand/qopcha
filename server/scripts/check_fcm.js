'use strict';
const f = require('/app/src/fcm.js');
const m = f.tryInit();
console.log(m ? 'fcm_ready' : 'fcm_null');
