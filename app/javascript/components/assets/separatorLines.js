const map = {
  // This is used by AMCharts to draw separatorLines for the Territory Map.
  // The actual data will be served from the server, but the lines must be there on initialization
  // (as far as I can tell anyway)
  type: 'FeatureCollection',
  features: [
    {
      type: 'Feature',
      geometry: {
        type: 'LineString',
        coordinates: [
          [-93.5, 22.5],
          [-85.5, 22.5],
          [-85.5, 31],
          [-85.5, 15],
          [-85.5, 22.5],
          [-75.75, 22.5],
          [-75.75, 15],
          [-75.75, 31],
          [-75.75, 22.5],
          [-69.25, 22.5],
          [-69.25, 31],
          [-69.25, 15],
          [-69.25, 22.5],
          [-64, 22.5],
        ],
      },
      properties: {
        name: 'Divider 1',
        id: 'div1',
        TYPE: 'Divider',
      },
      id: 'div1',
    },
  ],
};
export default map;
