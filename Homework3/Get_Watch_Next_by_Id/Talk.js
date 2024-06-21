const mongoose = require('mongoose');

const talk_schema = new mongoose.Schema({
    _id: String,
    title: String,
    url: String,
    related_videos: Array
}, { collection: 'tedx_data10' });

module.exports = mongoose.model('talk', talk_schema);