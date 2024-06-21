const mongoose = require('mongoose');

const talk_schema = new mongoose.Schema({
    _id: String,
    title: String,
    url: String,
    transcript: Array
}, { collection: 'tedx_data11' });

module.exports = mongoose.model('talk', talk_schema);