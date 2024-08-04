
function loadGoogleMapsApi(apiKey, callback) {
    const script = document.createElement('script');
    script.src = `https://maps.googleapis.com/maps/api/js?key=${apiKey}&libraries=visualization`;
    script.async = true;
    script.onload = callback;
    document.head.appendChild(script);
}

function initMap() {
    const map = new google.maps.Map(document.getElementById('map'), {
        center: {lat: 0, lng: 0},
        zoom: 1,
    });
    fetch('http://localhost:8080/heatmap-data')
        .then(response => response.json())
        .then(data => {
            const heatmapData = [];
            const markers = [];
            data.forEach(item => {
                const [lat, lng, essid] = item;
                if (lat && lng && essid && lat !== 'undefined' && lng !== 'undefined') {
                    const latLng = new google.maps.LatLng(parseFloat(lat), parseFloat(lng));
                    heatmapData.push(latLng);
                    const marker = new google.maps.Marker({
                        position: latLng,
                        map: map,
                        title: essid,
                    });
                    markers.push(marker);
                }
            });
            const heatmap = new google.maps.visualization.HeatmapLayer({
                data: heatmapData,
                map: map,
                radius: 20,
                opacity: 0.6,
            });

            document.getElementById('toggleHeatmap').addEventListener('click', () => {
                const currentVisibility = heatmap.getMap();
                heatmap.setMap(currentVisibility ? null : map);
            });

            const bounds = new google.maps.LatLngBounds();
            heatmapData.forEach(latLng => bounds.extend(latLng));
            map.fitBounds(bounds);
        })
        .catch(error => {
            console.error('Error fetching heatmap data: ', error);
        });
}

window.onload = function() {
    loadGoogleMapsApi(CONFIG.GOOGLE_MAPS_API_KEY, initMap);
};
