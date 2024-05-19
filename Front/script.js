document.getElementById('transactionForm').addEventListener('submit', function(event) {
    event.preventDefault();

    const soldQuantity = document.getElementById('soldQuantity').value;
    const branchId = document.getElementById('branchId').value;
    const medicationId = document.getElementById('medicationId').value;
    const customerId = document.getElementById('customerId').value;
    const employeeId = document.getElementById('employeeId').value;

    if (branchId < 1 || branchId > 5) {
        const messageElement = document.getElementById('responseMessage');
        messageElement.style.display = 'block';
        messageElement.textContent = 'Error: Branch ID must be between 1 and 5.';
        messageElement.className = '';
        return; 
    }

    const url = `http://localhost:8000/process_sale_transaction/?sold_quantity=${soldQuantity}&branch_id=${branchId}&medication_id=${medicationId}&customer_id=${customerId}&employee_id=${employeeId}`;

    fetch(url, {
        method: 'POST',
    })
    .then(response => {
        if (response.ok) {
            return response.json();
        } else {
            throw new Error('Network response was not ok.');
        }
    })
    .then(data => {
        const messageElement = document.getElementById('responseMessage');
        messageElement.style.display = 'block';
        messageElement.textContent = 'Transaction processed successfully!';
        messageElement.className = 'success-message'; 
    })
    .catch((error) => {
        console.error('Error:', error);
        const messageElement = document.getElementById('responseMessage');
        messageElement.style.display = 'block';
        messageElement.textContent = 'Failed to process transaction: ' + error.message;
        messageElement.className = ''; 
    });
});
