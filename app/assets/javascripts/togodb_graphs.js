const redrawGraphPage = (columnId) => {
    console.log(`togodb_graph.js: redrawGraphPage(${columnId})`);

    fetch(`/togodb_columns/${columnId}/graph_edit_html`)
        .then((response) => {
            if (!response.ok) {
                throw new Error(`HTTP error! Status: ${response.status}`);
            }

            return response.text();
        })
        .then((response) => {
            const wrapperElement = document.getElementById("togodb_columns_graph_contents");
            wrapperElement.innerHTML = response;
        });
}
