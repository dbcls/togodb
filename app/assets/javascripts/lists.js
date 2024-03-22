(function() {
    document.querySelectorAll(".togodb-process-request-btn").forEach((btn) => {
        btn.addEventListener("click", (event) => {
            const modelId = event.target.dataset.productionRequestId;
            const modelElem = document.querySelector("#process-request-form input[name='production_request_id']");
            modelElem.value = modelId;
        });
    })
})();
