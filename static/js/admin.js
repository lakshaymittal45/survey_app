// ==================== TAB SWITCHING ====================

// Main tab switching
document.querySelectorAll('.tab-btn').forEach(btn => {
    btn.addEventListener('click', () => {
        const tabId = btn.getAttribute('data-tab');
        
        // Remove active class from all tabs and contents
        document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
        document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));
        
        // Add active class to clicked tab and corresponding content
        btn.classList.add('active');
        document.getElementById(tabId).classList.add('active');
        
        // Load data when switching tabs
        if (tabId === 'manage-questionnaire') {
            loadSections();
        } else if (tabId === 'manage-location') {
            loadAllStates();
        } else if (tabId === 'households') {
            loadHouseholds();
        } else if (tabId === 'statistics') {
            loadStatistics();
        }
    });
});

// Account sub-tab switching
document.querySelectorAll('.account-tab-btn').forEach(btn => {
    btn.addEventListener('click', () => {
        const tabId = btn.getAttribute('data-account-tab');
        const parent = btn.closest('.account-tabs').parentElement;
        
        // Remove active class from all account tabs and contents
        parent.querySelectorAll('.account-tab-btn').forEach(b => b.classList.remove('active'));
        parent.querySelectorAll('.account-tab-content').forEach(c => c.classList.remove('active'));
        
        // Add active class to clicked tab and corresponding content
        btn.classList.add('active');
        document.getElementById(tabId).classList.add('active');
        
        // Load data when switching to view tabs
        if (tabId === 'view-users') {
            loadUsers();
        } else if (tabId === 'view-admins') {
            loadAdmins();
        } else if (tabId === 'sections-tab') {
            loadSections();
        } else if (tabId === 'questions-tab') {
            loadQuestions();
        }
    });
});
let allSubCenters = [];
let browseSubCenters = [];
let selectedSubCenterId = null;
let selectedSubCenter = null;
let selectedBlockId = null;
let selectedBlock = null;

async function selectBlock(blockId) {
    selectedBlockId = blockId;
    selectedSubCenterId = null;
    
    document.getElementById('browseSubCenterSearch').disabled = false;
    document.getElementById('browseSubCenterSearch').placeholder = "Type to search sub-centers...";
    document.getElementById('browseSubCenterSearch').value = '';
    
    try {
        const response = await apiFetch(`/api/sub-centers/${blockId}`);
        browseSubCenters = await response.json();
        displayBrowseSubCenters(browseSubCenters);
        document.getElementById('villagesList').innerHTML = '<div class="empty-state">Select a sub-center first</div>';
    } catch (error) {
        showMessage('Error loading sub-centers: ' + error.message, 'error');
    }
}
// Location sub-tab switching
document.querySelectorAll('.location-tab-btn').forEach(btn => {
    btn.addEventListener('click', () => {
        const tabId = btn.getAttribute('data-location-tab');
        const parent = btn.closest('.location-tabs').parentElement;
        
        // Remove active class from all location tabs and contents
        parent.querySelectorAll('.location-tab-btn').forEach(b => b.classList.remove('active'));
        parent.querySelectorAll('.location-tab-content').forEach(c => c.classList.remove('active'));
        
        // Add active class to clicked tab and corresponding content
        btn.classList.add('active');
        document.getElementById(tabId).classList.add('active');
        
        // Load data when switching to view tabs
        if (tabId === 'view-states') {
            loadAllStates();
        } else if (tabId === 'view-districts') {
            loadAllDistricts();
        } else if (tabId === 'view-blocks') {
            loadAllBlocks();
        } else if (tabId === 'view-villages') {
            loadAllVillages();
        }
    });
});

// ==================== PAGE INITIALIZATION ====================

document.addEventListener('DOMContentLoaded', () => {
    loadStatesForAllDropdowns();
    loadSections();
    loadStatistics();
});

// ==================== QUESTIONNAIRE MANAGEMENT ====================

// ---- Sections Management ----

async function loadSections() {
    try {
        const response = await fetch('/api/admin/sections');
        if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
        
        const sections = await response.json();
        
        const sectionsList = document.getElementById('sectionsList');
        const questionSection = document.getElementById('questionSection');
        
        if (!sectionsList) return;
        
        if (sections.length === 0) {
            sectionsList.innerHTML = '<div class="empty-state"><p>No sections yet. Create one to get started!</p></div>';
            if (questionSection) questionSection.innerHTML = '<option value="">Select Section</option>';
            return;
        }
        
        // Display sections
        let html = '';
        sections.forEach(section => {
            html += `
                <div class="section-card">
                    <h4>${escapeHtml(section.section_title)}</h4>
                    <div class="section-actions">
                        <button class="btn btn-edit" onclick="openEditSectionModal(${section.section_id}, '${escapeHtml(section.section_title).replace(/'/g, "\\'")}')">
                            ✎ Edit
                        </button>
                        <button class="btn btn-danger" onclick="deleteSection(${section.section_id})">
                            🗑 Delete
                        </button>
                    </div>
                </div>
            `;
        });
        sectionsList.innerHTML = html;
        
        // Update dropdown
        if (questionSection) {
            let options = '<option value="">Select Section</option>';
            sections.forEach(section => {
                options += `<option value="${section.section_id}">${escapeHtml(section.section_title)}</option>`;
            });
            questionSection.innerHTML = options;
        }
        
    } catch (error) {
        showMessage('Error loading sections: ' + error.message, 'error');
    }
}

const addSectionForm = document.getElementById('addSectionForm');
if (addSectionForm) {
    addSectionForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        
        const title = document.getElementById('sectionTitle').value.trim();
        
        if (!title) {
            showMessage('Section title is required', 'error');
            return;
        }
        
        try {
            const response = await fetch('/api/admin/section', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ title })
            });
            
            if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
            
            const result = await response.json();
            
            if (result.success) {
                showMessage('✓ Section added successfully!', 'success');
                e.target.reset();
                loadSections();
                loadQuestions();
            } else {
                showMessage(`Error: ${result.error}`, 'error');
            }
        } catch (error) {
            showMessage('Error adding section: ' + error.message, 'error');
        }
    });
}

function openEditSectionModal(id, title) {
    const modal = document.getElementById('editSectionModal');
    const input = document.getElementById('editSectionTitle');
    
    if (!modal || !input) return;
    
    input.value = title;
    input.dataset.sectionId = id;
    
    openModal('editSectionModal');
}

const editSectionForm = document.getElementById('editSectionForm');
if (editSectionForm) {
    editSectionForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        
        const titleInput = document.getElementById('editSectionTitle');
        const title = titleInput.value.trim();
        const sectionId = titleInput.dataset.sectionId;
        
        if (!title) {
            showMessage('Section title is required', 'error');
            return;
        }
        
        try {
            const response = await fetch(`/api/admin/section/${sectionId}`, {
                method: 'PUT',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ title })
            });
            
            if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
            
            const result = await response.json();
            
            if (result.success) {
                showMessage('✓ Section updated successfully!', 'success');
                closeModal('editSectionModal');
                loadSections();
                loadQuestions();
            } else {
                showMessage(`Error: ${result.error}`, 'error');
            }
        } catch (error) {
            showMessage('Error updating section: ' + error.message, 'error');
        }
    });
}

async function deleteSection(id) {
    if (!confirm('Are you sure? This will delete the section and all its questions!')) {
        return;
    }
    
    try {
        const response = await fetch(`/api/admin/delete/questionnaire_sections/${id}`, {
            method: 'DELETE'
        });
        
        if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
        
        const result = await response.json();
        
        if (result.success) {
            showMessage('✓ Section deleted successfully!', 'success');
            loadSections();
            loadQuestions();
        } else {
            showMessage(`Error: ${result.error}`, 'error');
        }
    } catch (error) {
        showMessage('Error deleting section: ' + error.message, 'error');
    }
}

// ---- Questions Management ----

async function loadQuestions() {
    try {
        const response = await fetch('/api/admin/questions');
        if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
        
        const questions = await response.json();
        
        const questionsList = document.getElementById('questionsList');
        
        if (!questionsList) return;
        
        if (questions.length === 0) {
            questionsList.innerHTML = '<div class="empty-state"><p>No questions yet. Create one to get started!</p></div>';
            return;
        }
        
        let html = '';
        questions.forEach(q => {
            html += `
                <div class="question-item">
                    <div class="question-info">
                        <p><strong>${escapeHtml(q.section_title)}</strong></p>
                        <p>${escapeHtml(q.question_text)}</p>
                        <span class="question-type">${q.question_type}</span>
                        <span class="question-type">${q.answer_type}</span>
                    </div>
                    <div style="display: flex; gap: 8px;">
                        <button class="btn btn-edit" onclick="openEditQuestionModal(${q.question_id})">✎ Edit</button>
                        <button class="btn btn-danger" onclick="deleteQuestion(${q.question_id})">🗑 Delete</button>
                    </div>
                </div>
            `;
        });
        
        questionsList.innerHTML = html;
    } catch (error) {
        showMessage('Error loading questions: ' + error.message, 'error');
    }
}

const addQuestionForm = document.getElementById('addQuestionForm');
if (addQuestionForm) {
    addQuestionForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        
        const sectionId = parseInt(document.getElementById('questionSection').value);
        const questionText = document.getElementById('questionText').value.trim();
        const questionType = document.getElementById('questionType').value;
        const answerType = document.getElementById('answerType').value;
        
        if (!sectionId || !questionText) {
            showMessage('All fields are required', 'error');
            return;
        }
        
        try {
            const response = await fetch('/api/admin/question', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    section_id: sectionId,
                    text: questionText,
                    type: questionType,
                    answer_type: answerType
                })
            });
            
            if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
            
            const result = await response.json();
            
            if (result.success) {
                showMessage('✓ Question added successfully!', 'success');
                e.target.reset();
                loadQuestions();
            } else {
                showMessage(`Error: ${result.error}`, 'error');
            }
        } catch (error) {
            showMessage('Error adding question: ' + error.message, 'error');
        }
    });
}

async function openEditQuestionModal(id) {
    try {
        const response = await fetch('/api/admin/questions');
        if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
        
        const questions = await response.json();
        const question = questions.find(q => q.question_id === id);
        
        if (!question) {
            showMessage('Question not found', 'error');
            return;
        }
        
        // Load sections for dropdown
        const sectionsResponse = await fetch('/api/admin/sections');
        if (!sectionsResponse.ok) throw new Error(`HTTP error! status: ${sectionsResponse.status}`);
        
        const sections = await sectionsResponse.json();
        
        let options = '';
        sections.forEach(s => {
            options += `<option value="${s.section_id}" ${s.section_id === question.section_id ? 'selected' : ''}>${escapeHtml(s.section_title)}</option>`;
        });
        
        const editQuestionSection = document.getElementById('editQuestionSection');
        const editQuestionText = document.getElementById('editQuestionText');
        
        if (editQuestionSection) editQuestionSection.innerHTML = options;
        if (editQuestionText) {
            editQuestionText.value = question.question_text;
            editQuestionText.dataset.questionId = id;
        }
        
        const editQuestionType = document.getElementById('editQuestionType');
        const editAnswerType = document.getElementById('editAnswerType');
        
        if (editQuestionType) editQuestionType.value = question.question_type;
        if (editAnswerType) editAnswerType.value = question.answer_type;
        
        openModal('editQuestionModal');
    } catch (error) {
        showMessage('Error opening edit modal: ' + error.message, 'error');
    }
}

const editQuestionForm = document.getElementById('editQuestionForm');
if (editQuestionForm) {
    editQuestionForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        
        const editQuestionText = document.getElementById('editQuestionText');
        const questionId = editQuestionText.dataset.questionId;
        const sectionId = parseInt(document.getElementById('editQuestionSection').value);
        const questionText = editQuestionText.value.trim();
        const questionType = document.getElementById('editQuestionType').value;
        const answerType = document.getElementById('editAnswerType').value;
        
        if (!sectionId || !questionText) {
            showMessage('All fields are required', 'error');
            return;
        }
        
        try {
            const response = await fetch(`/api/admin/question/${questionId}`, {
                method: 'PUT',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    section_id: sectionId,
                    text: questionText,
                    type: questionType,
                    answer_type: answerType
                })
            });
            
            if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
            
            const result = await response.json();
            
            if (result.success) {
                showMessage('✓ Question updated successfully!', 'success');
                closeModal('editQuestionModal');
                loadQuestions();
            } else {
                showMessage(`Error: ${result.error}`, 'error');
            }
        } catch (error) {
            showMessage('Error updating question: ' + error.message, 'error');
        }
    });
}

async function deleteQuestion(id) {
    if (!confirm('Are you sure you want to delete this question?')) {
        return;
    }
    
    try {
        const response = await fetch(`/api/admin/delete/questionnaire_questions/${id}`, {
            method: 'DELETE'
        });
        
        if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
        
        const result = await response.json();
        
        if (result.success) {
            showMessage('✓ Question deleted successfully!', 'success');
            loadQuestions();
        } else {
            showMessage(`Error: ${result.error}`, 'error');
        }
    } catch (error) {
        showMessage('Error deleting question: ' + error.message, 'error');
    }
}

// ==================== ACCOUNT MANAGEMENT ====================

const createAdminForm = document.getElementById('createAdminForm');
if (createAdminForm) {
    createAdminForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        
        const password = e.target.querySelector('[name="password"]').value;
        const confirmPassword = e.target.querySelector('[name="confirm_password"]').value;
        
        if (password !== confirmPassword) {
            showMessage('Passwords do not match', 'error');
            return;
        }
        
        if (password.length < 6) {
            showMessage('Password must be at least 6 characters', 'error');
            return;
        }
        
        const formData = {
            username: e.target.querySelector('[name="username"]').value.trim(),
            password: password
        };
        
        if (!formData.username) {
            showMessage('Username is required', 'error');
            return;
        }
        
        try {
            const response = await fetch('/api/admin/create-admin', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(formData)
            });
            
            if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
            
            const result = await response.json();
            
            if (result.success) {
                showMessage('✓ Admin created successfully', 'success');
                e.target.reset();
                loadAdmins();
            } else {
                showMessage(`Error: ${result.error}`, 'error');
            }
        } catch (error) {
            showMessage('Error creating admin: ' + error.message, 'error');
        }
    });
}

const createUserForm = document.getElementById('createUserForm');
if (createUserForm) {
    createUserForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        
        const password = e.target.querySelector('[name="password"]').value;
        const confirmPassword = e.target.querySelector('[name="confirm_password"]').value;
        
        if (password !== confirmPassword) {
            showMessage('Passwords do not match', 'error');
            return;
        }
        
        if (password.length < 6) {
            showMessage('Password must be at least 6 characters', 'error');
            return;
        }
        
        const formData = {
            username: e.target.querySelector('[name="username"]').value.trim(),
            password: password,
            full_name: e.target.querySelector('[name="full_name"]').value.trim()
        };
        
        if (!formData.username) {
            showMessage('Username is required', 'error');
            return;
        }
        
        try {
            const response = await fetch('/api/admin/create-user', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(formData)
            });
            
            if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
            
            const result = await response.json();
            
            if (result.success) {
                showMessage('✓ User created successfully', 'success');
                e.target.reset();
                loadUsers();
            } else {
                showMessage(`Error: ${result.error}`, 'error');
            }
        } catch (error) {
            showMessage('Error creating user: ' + error.message, 'error');
        }
    });
}

async function loadUsers() {
    try {
        const response = await fetch('/api/admin/users');
        if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
        
        const users = await response.json();
        
        const displayDiv = document.getElementById('usersDisplay');
        if (!displayDiv) return;
        
        if (users.length === 0) {
            displayDiv.innerHTML = '<p>No users found</p>';
            return;
        }
        
        let html = `
            <table class="data-table">
                <thead>
                    <tr>
                        <th>User ID</th>
                        <th>Username</th>
                        <th>Full Name</th>
                        <th>Created At</th>
                        <th>Action</th>
                    </tr>
                </thead>
                <tbody>
        `;
        
        users.forEach(user => {
            const createdDate = new Date(user.created_at).toLocaleString();
            html += `
                <tr>
                    <td>${user.user_id}</td>
                    <td>${escapeHtml(user.username)}</td>
                    <td>${escapeHtml(user.full_name || 'N/A')}</td>
                    <td>${createdDate}</td>
                    <td>
                        <button class="btn btn-danger" onclick="deleteUser(${user.user_id})">Delete</button>
                    </td>
                </tr>
            `;
        });
        
        html += '</tbody></table>';
        displayDiv.innerHTML = html;
    } catch (error) {
        showMessage('Error loading users: ' + error.message, 'error');
    }
}

async function loadAdmins() {
    try {
        const response = await fetch('/api/admin/admins');
        if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
        
        const admins = await response.json();
        
        const displayDiv = document.getElementById('adminsDisplay');
        if (!displayDiv) return;
        
        if (admins.length === 0) {
            displayDiv.innerHTML = '<p>No admins found</p>';
            return;
        }
        
        let html = `
            <table class="data-table">
                <thead>
                    <tr>
                        <th>Admin ID</th>
                        <th>Username</th>
                        <th>Created At</th>
                        <th>Action</th>
                    </tr>
                </thead>
                <tbody>
        `;
        
        admins.forEach(admin => {
            const createdDate = new Date(admin.created_at).toLocaleString();
            html += `
                <tr>
                    <td>${admin.admin_id}</td>
                    <td>${escapeHtml(admin.username)}</td>
                    <td>${createdDate}</td>
                    <td>
                        <button class="btn btn-danger" onclick="deleteAdmin(${admin.admin_id})">Delete</button>
                    </td>
                </tr>
            `;
        });
        
        html += '</tbody></table>';
        displayDiv.innerHTML = html;
    } catch (error) {
        showMessage('Error loading admins: ' + error.message, 'error');
    }
}

async function deleteUser(userId) {
    if (!confirm('Are you sure you want to delete this user?')) {
        return;
    }
    
    try {
        const response = await fetch(`/api/admin/delete-user/${userId}`, {
            method: 'DELETE'
        });
        
        if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
        
        const result = await response.json();
        
        if (result.success) {
            showMessage('✓ User deleted successfully', 'success');
            loadUsers();
        } else {
            showMessage(`Error: ${result.error}`, 'error');
        }
    } catch (error) {
        showMessage('Error deleting user: ' + error.message, 'error');
    }
}

async function deleteAdmin(adminId) {
    if (!confirm('Are you sure you want to delete this admin?')) {
        return;
    }
    
    try {
        const response = await fetch(`/api/admin/delete-admin/${adminId}`, {
            method: 'DELETE'
        });
        
        if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
        
        const result = await response.json();
        
        if (result.success) {
            showMessage('✓ Admin deleted successfully', 'success');
            loadAdmins();
        } else {
            showMessage(`Error: ${result.error}`, 'error');
        }
    } catch (error) {
        showMessage('Error deleting admin: ' + error.message, 'error');
    }
}

// ==================== LOCATION DATA MANAGEMENT ====================

// Load states for all dropdowns
async function loadStatesForAllDropdowns() {
    try {
        console.log('Loading states for all dropdowns...');
        const response = await fetch('/api/states');
        console.log('States API response status:', response.status);
        if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
        
        const states = await response.json();
        console.log('States loaded:', states.length, 'states');
        
        const stateSelects = ['districtState', 'blockState', 'villageState', 'subCenterState', 'villageState'];
        
        stateSelects.forEach(selectId => {
            const select = document.getElementById(selectId);
            if (select) {
                console.log(`Populating ${selectId} with ${states.length} states`);
                select.innerHTML = '<option value="">Select State</option>';
                states.forEach(state => {
                    const option = document.createElement('option');
                    option.value = state.state_id;
                    option.textContent = state.name;
                    select.appendChild(option);
                });
            } else {
                console.warn(`Element ${selectId} not found`);
            }
        });
    } catch (error) {
        console.error('Error loading states:', error);
        showMessage('Error loading states: ' + error.message, 'error');
    }
}

// ==================== BROWSE & EDIT DROPDOWNS ====================

let browseData = {
    selectedState: null,
    selectedDistrict: null,
    selectedBlock: null,
    selectedSubCenter: null,
    selectedVillage: null,
    allStates: [],
    allDistricts: [],
    allBlocks: [],
    allSubCenters: [],
    allVillages: []
};

async function initializeBrowseDropdowns() {
    try {
        // Check if browse elements exist
        const stateSelect = document.getElementById('browseStateSelect');
        if (!stateSelect) {
            console.log('Browse dropdowns not on this page, skipping initialization');
            return; // Elements don't exist on this page
        }
        
        console.log('Initializing browse dropdowns...');
        
        // Load only states and districts initially
        const statesRes = await fetch('/api/admin/all-states');
        console.log('States API response status:', statesRes.status);
        if (!statesRes.ok) throw new Error(`HTTP error! status: ${statesRes.status}`);
        
        const districtsRes = await fetch('/api/admin/all-districts');
        console.log('Districts API response status:', districtsRes.status);
        if (!districtsRes.ok) throw new Error(`HTTP error! status: ${districtsRes.status}`);

        browseData.allStates = await statesRes.json();
        browseData.allDistricts = await districtsRes.json();

        console.log('States loaded:', browseData.allStates.length);
        console.log('Districts loaded:', browseData.allDistricts.length);

        // Populate states dropdown
        if (stateSelect) {
            stateSelect.innerHTML = '<option value="">Select a State</option>';
            browseData.allStates.forEach(state => {
                const option = document.createElement('option');
                option.value = state.state_id;
                option.textContent = state.name;
                stateSelect.appendChild(option);
            });
        }
    } catch (error) {
        console.error('Error initializing browse dropdowns:', error);
        showMessage('Error loading states: ' + error.message, 'error');
    }
}

async function handleBrowseStateChange() {
    const stateSelect = document.getElementById('browseStateSelect');
    const districtSelect = document.getElementById('browseDistrictSelect');
    const blockSelect = document.getElementById('browseBlockSelect');
    const subCenterSelect = document.getElementById('browseSubCenterSelect');
    const villageSelect = document.getElementById('browseVillageSelect');

    if (!stateSelect || !districtSelect) return;

    browseData.selectedState = stateSelect.value;
    browseData.selectedDistrict = null;
    browseData.selectedBlock = null;
    browseData.selectedSubCenter = null;
    browseData.selectedVillage = null;

    // Reset dependent dropdowns
    districtSelect.innerHTML = '<option value="">Select a District</option>';
    if (blockSelect) blockSelect.innerHTML = '<option value="">Select a Block</option>';
    if (subCenterSelect) subCenterSelect.innerHTML = '<option value="">Select a Sub-Center</option>';
    if (villageSelect) villageSelect.innerHTML = '<option value="">Select a Village</option>';
    
    districtSelect.disabled = !browseData.selectedState;
    if (blockSelect) blockSelect.disabled = true;
    if (subCenterSelect) subCenterSelect.disabled = true;
    if (villageSelect) villageSelect.disabled = true;

    if (browseData.selectedState) {
        const districts = browseData.allDistricts.filter(d => d.state_id == browseData.selectedState);
        districts.forEach(district => {
            const option = document.createElement('option');
            option.value = district.district_id;
            option.textContent = district.name;
            districtSelect.appendChild(option);
        });
    }
    hideBrowseActionButtons();
}

async function handleBrowseDistrictChange() {
    const districtSelect = document.getElementById('browseDistrictSelect');
    const blockSelect = document.getElementById('browseBlockSelect');
    const subCenterSelect = document.getElementById('browseSubCenterSelect');
    const villageSelect = document.getElementById('browseVillageSelect');

    if (!districtSelect || !blockSelect) return;

    browseData.selectedDistrict = districtSelect.value;
    browseData.selectedBlock = null;
    browseData.selectedSubCenter = null;
    browseData.selectedVillage = null;

    // Reset dependent dropdowns
    blockSelect.innerHTML = '<option value="">Select a Block</option>';
    if (subCenterSelect) subCenterSelect.innerHTML = '<option value="">Select a Sub-Center</option>';
    if (villageSelect) villageSelect.innerHTML = '<option value="">Select a Village</option>';
    blockSelect.disabled = !browseData.selectedDistrict;
    if (subCenterSelect) subCenterSelect.disabled = true;
    if (villageSelect) villageSelect.disabled = true;

    if (browseData.selectedDistrict) {
        try {
            const response = await fetch(`/api/blocks/${browseData.selectedDistrict}`);
            const blocks = await response.json();
            browseData.allBlocks = blocks;
            blocks.forEach(block => {
                const option = document.createElement('option');
                option.value = block.block_id;
                option.textContent = block.name;
                blockSelect.appendChild(option);
            });
        } catch (error) {
            showMessage('Error loading blocks: ' + error.message, 'error');
        }
    }
    hideBrowseActionButtons();
}

async function handleBrowseBlockChange() {
    const blockSelect = document.getElementById('browseBlockSelect');
    const subCenterSelect = document.getElementById('browseSubCenterSelect');
    const villageSelect = document.getElementById('browseVillageSelect');

    if (!blockSelect || !subCenterSelect) return;

    browseData.selectedBlock = blockSelect.value;
    browseData.selectedSubCenter = null;
    browseData.selectedVillage = null;

    // Reset dependent dropdowns
    subCenterSelect.innerHTML = '<option value="">Select a Sub-Center</option>';
    if (villageSelect) villageSelect.innerHTML = '<option value="">Select a Village</option>';
    subCenterSelect.disabled = !browseData.selectedBlock;
    if (villageSelect) villageSelect.disabled = true;

    if (browseData.selectedBlock) {
        try {
            const response = await fetch(`/api/sub-centers/${browseData.selectedBlock}`);
            const subCenters = await response.json();
            browseData.allSubCenters = subCenters;
            subCenters.forEach(subCenter => {
                const option = document.createElement('option');
                option.value = subCenter.sub_center_id;
                option.textContent = subCenter.name;
                subCenterSelect.appendChild(option);
            });
        } catch (error) {
            showMessage('Error loading sub-centers: ' + error.message, 'error');
        }
    }
    hideBrowseActionButtons();
}

async function handleBrowseSubCenterChange() {
    const subCenterSelect = document.getElementById('browseSubCenterSelect');
    const villageSelect = document.getElementById('browseVillageSelect');

    if (!subCenterSelect || !villageSelect) return;

    browseData.selectedSubCenter = subCenterSelect.value;
    browseData.selectedVillage = null;

    // Reset villages dropdown
    villageSelect.innerHTML = '<option value="">Select a Village</option>';
    villageSelect.disabled = !browseData.selectedSubCenter;

    if (browseData.selectedSubCenter) {
        try {
            const response = await fetch(`/api/villages/by-subcenter/${browseData.selectedSubCenter}`);
            const villages = await response.json();
            browseData.allVillages = villages;
            villages.forEach(village => {
                const option = document.createElement('option');
                option.value = village.village_id;
                option.textContent = village.name;
                villageSelect.appendChild(option);
            });
        } catch (error) {
            showMessage('Error loading villages: ' + error.message, 'error');
        }
    }
    hideBrowseActionButtons();
}

function showBrowseActionButtons() {
    const actionButtons = document.getElementById('browseActionButtons');
    if (actionButtons) {
        actionButtons.style.display = 'block';
    }
}

function hideBrowseActionButtons() {
    const actionButtons = document.getElementById('browseActionButtons');
    if (actionButtons) {
        actionButtons.style.display = 'none';
    }
}

function editBrowseItem() {
    const villageSelect = document.getElementById('browseVillageSelect');
    if (villageSelect && villageSelect.value) {
        const village = browseData.allVillages.find(v => v.village_id == villageSelect.value);
        if (village) {
            editVillage(village.village_lgd_code, village.name, village.district_id, village.block_id);
        }
    }
}

function deleteBrowseItem() {
    const villageSelect = document.getElementById('browseVillageSelect');
    if (villageSelect && villageSelect.value) {
        const village = browseData.allVillages.find(v => v.village_id == villageSelect.value);
        if (village) {
            deleteVillage(village.village_lgd_code);
        }
    }
}

// Initialize browse dropdowns on page load
window.addEventListener('load', initializeBrowseDropdowns);

// Add event listener to village dropdown
document.addEventListener('DOMContentLoaded', () => {
    const villageSelect = document.getElementById('browseVillageSelect');
    if (villageSelect) {
        villageSelect.addEventListener('change', function() {
            if (this.value) {
                showBrowseActionButtons();
            } else {
                hideBrowseActionButtons();
            }
        });
    }
});

// Load all states with details
async function loadAllStates() {
    try {
        const response = await fetch('/api/admin/all-states');
        if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
        
        const states = await response.json();
        
        const statesList = document.getElementById('statesList');
        if (!statesList) return;
        
        if (states.length === 0) {
            statesList.innerHTML = '<div class="empty-state"><p>No states found.</p></div>';
            return;
        }
        
        let html = `
            <table class="data-table">
                <thead>
                    <tr>
                        <th>State ID</th>
                        <th>Name</th>
                        <th>Territory Type</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
        `;
        
        states.forEach(state => {
            html += `
                <tr>
                    <td>${state.state_id}</td>
                    <td>${escapeHtml(state.name)}</td>
                    <td>${state.territory_type}</td>
                    <td>
                        <button class="btn btn-danger" onclick="deleteRecord('states', ${state.state_id})">Delete</button>
                    </td>
                </tr>
            `;
        });
        
        html += '</tbody></table>';
        statesList.innerHTML = html;
    } catch (error) {
        showMessage('Error loading states: ' + error.message, 'error');
    }
}

// Load all districts with state names
async function loadAllDistricts() {
    try {
        const response = await fetch('/api/admin/all-districts');
        if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
        
        const districts = await response.json();
        
        const districtsList = document.getElementById('districtsList');
        if (!districtsList) return;
        
        if (districts.length === 0) {
            districtsList.innerHTML = '<div class="empty-state"><p>No districts found.</p></div>';
            return;
        }
        
        let html = `
            <table class="data-table">
                <thead>
                    <tr>
                        <th>District ID</th>
                        <th>Name</th>
                        <th>State</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
        `;
        
        districts.forEach(district => {
            html += `
                <tr>
                    <td>${district.district_id}</td>
                    <td>${escapeHtml(district.name)}</td>
                    <td>${escapeHtml(district.state_name)}</td>
                    <td>
                        <button class="btn btn-danger" onclick="deleteRecord('districts', ${district.district_id})">Delete</button>
                    </td>
                </tr>
            `;
        });
        
        html += '</tbody></table>';
        districtsList.innerHTML = html;
    } catch (error) {
        showMessage('Error loading districts: ' + error.message, 'error');
    }
}

// Load all blocks with district names
async function loadAllBlocks() {
    try {
        const response = await fetch('/api/admin/all-blocks');
        if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
        
        const blocks = await response.json();
        
        const blocksList = document.getElementById('blocksList');
        if (!blocksList) return;
        
        if (blocks.length === 0) {
            blocksList.innerHTML = '<div class="empty-state"><p>No blocks found.</p></div>';
            return;
        }
        
        let html = `
            <table class="data-table">
                <thead>
                    <tr>
                        <th>Block ID</th>
                        <th>Name</th>
                        <th>District</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
        `;
        
        blocks.forEach(block => {
            html += `
                <tr>
                    <td>${block.block_id}</td>
                    <td>${escapeHtml(block.name)}</td>
                    <td>${escapeHtml(block.district_name)}</td>
                    <td>
                        <button class="btn btn-danger" onclick="deleteRecord('blocks', ${block.block_id})">Delete</button>
                    </td>
                </tr>
            `;
        });
        
        html += '</tbody></table>';
        blocksList.innerHTML = html;
    } catch (error) {
        showMessage('Error loading blocks: ' + error.message, 'error');
    }
}

// Load all villages with district and block names
async function loadAllVillages() {
    try {
        const response = await fetch('/api/admin/all-villages');
        if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
        
        const villages = await response.json();
        
        const villagesList = document.getElementById('villagesList');
        if (!villagesList) return;
        
        if (villages.length === 0) {
            villagesList.innerHTML = '<div class="empty-state"><p>No villages found.</p></div>';
            return;
        }
        
        let html = `
            <table class="data-table">
                <thead>
                    <tr>
                        <th>Village LGD Code</th>
                        <th>Name</th>
                        <th>District</th>
                        <th>Block</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
        `;
        
        villages.forEach(village => {
            html += `
                <tr>
                    <td>${village.village_lgd_code}</td>
                    <td>${escapeHtml(village.name)}</td>
                    <td>${escapeHtml(village.district_name)}</td>
                    <td>${village.block_name ? escapeHtml(village.block_name) : 'N/A'}</td>
                    <td>
                        <button class="btn btn-danger" onclick="deleteRecord('villages', ${village.village_lgd_code})">Delete</button>
                    </td>
                </tr>
            `;
        });
        
        html += '</tbody></table>';
        villagesList.innerHTML = html;
    } catch (error) {
        showMessage('Error loading villages: ' + error.message, 'error');
    }
}

// ==================== BLOCK FORM HANDLERS ====================

async function loadBlockDistricts() {
    const stateId = document.getElementById('blockState').value;
    const districtEl = document.getElementById('blockDistrict');
    const blockNameEl = document.getElementById('blockName');
    
    districtEl.innerHTML = '<option value="">Loading...</option>';
    districtEl.disabled = true;
    blockNameEl.disabled = true;
    
    if (!stateId) {
        districtEl.innerHTML = '<option value="">Select State first</option>';
        return;
    }
    
    try {
        const response = await fetch(`/api/districts/${stateId}`);
        const districts = await response.json();
        
        districtEl.innerHTML = '<option value="">Select District</option>';
        districts.forEach(d => {
            const option = document.createElement('option');
            option.value = d.district_id;
            option.textContent = d.name;
            districtEl.appendChild(option);
        });
        districtEl.disabled = false;
    } catch (error) {
        showMessage('Error loading districts: ' + error.message, 'error');
    }
}

function loadBlockStates() {
    const districtId = document.getElementById('blockDistrict').value;
    document.getElementById('blockName').disabled = !districtId;
}

// Block form state change
const addBlockForm = document.getElementById('addBlockForm');
if (addBlockForm) {
    addBlockForm.addEventListener('change', async (e) => {
        if (e.target.id !== 'blockState') return;
        
        const stateId = e.target.value;
        const blockDistrict = document.getElementById('blockDistrict');
        
        blockDistrict.innerHTML = '<option value="">Select District</option>';
        blockDistrict.disabled = true;
        
        if (stateId) {
            try {
                const response = await fetch(`/api/districts/${stateId}`);
                if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
                
                const districts = await response.json();
                
                districts.forEach(district => {
                    const option = document.createElement('option');
                    option.value = district.district_id;
                    option.textContent = district.name;
                    blockDistrict.appendChild(option);
                });
                
                blockDistrict.disabled = false;
            } catch (error) {
                showMessage('Error loading districts: ' + error.message, 'error');
            }
        }
    });
}

// Village form state/district change
const addVillageForm = document.getElementById('addVillageForm');
if (addVillageForm) {
    addVillageForm.addEventListener('change', async (e) => {
        if (e.target.id === 'villageState') {
            const stateId = e.target.value;
            const villageDistrict = document.getElementById('villageDistrict');
            const villageBlock = document.getElementById('villageBlock');
            
            villageDistrict.innerHTML = '<option value="">Select District</option>';
            villageBlock.innerHTML = '<option value="">Select Block</option>';
            villageDistrict.disabled = true;
            villageBlock.disabled = true;
            
            if (stateId) {
                try {
                    const response = await fetch(`/api/districts/${stateId}`);
                    if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
                    
                    const districts = await response.json();
                    
                    districts.forEach(district => {
                        const option = document.createElement('option');
                        option.value = district.district_id;
                        option.textContent = district.name;
                        villageDistrict.appendChild(option);
                    });
                    
                    villageDistrict.disabled = false;
                } catch (error) {
                    showMessage('Error loading districts: ' + error.message, 'error');
                }
            }
        } else if (e.target.id === 'villageDistrict') {
            const districtId = e.target.value;
            const villageBlock = document.getElementById('villageBlock');
            
            villageBlock.innerHTML = '<option value="">Select Block</option>';
            villageBlock.disabled = true;
            
            if (districtId) {
                try {
                    const response = await fetch(`/api/blocks/${districtId}`);
                    if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
                    
                    const blocks = await response.json();
                    
                    blocks.forEach(block => {
                        const option = document.createElement('option');
                        option.value = block.block_id;
                        option.textContent = block.name;
                        villageBlock.appendChild(option);
                    });
                    
                    villageBlock.disabled = false;
                } catch (error) {
                    showMessage('Error loading blocks: ' + error.message, 'error');
                }
            }
        }
    });
}

// Block and Sub-Center select event listeners
const blockSelect = document.getElementById('blockSelect');
const subCenterSelect = document.getElementById('subCenter');
const villageSelect = document.getElementById('villageSelect');

if (blockSelect) {
    blockSelect.addEventListener('change', async function() {
        const blockId = this.value;
        selectedBlock = blockId;
        
        // Reset dependent fields
        if (subCenterSelect) {
            subCenterSelect.innerHTML = '<option value="">Loading...</option>';
            subCenterSelect.disabled = true;
        }
        if (villageSelect) {
            villageSelect.innerHTML = '<option value="">Select Sub-Center first</option>';
            villageSelect.disabled = true;
        }
        
        if (!blockId) {
            if (subCenterSelect) {
                subCenterSelect.innerHTML = '<option value="">Select Block first</option>';
            }
            return;
        }

        try {
            const response = await fetch(`/api/sub-centers/${blockId}`);
            const subCenters = await response.json();
            
            if (subCenterSelect) {
                subCenterSelect.innerHTML = '<option value="">Select Sub-Center</option>';
                subCenters.forEach(subCenter => {
                    const option = document.createElement('option');
                    option.value = subCenter.sub_center_id;
                    option.textContent = subCenter.name;
                    subCenterSelect.appendChild(option);
                });
                subCenterSelect.disabled = false;
            }
        } catch (error) {
            showMessage('Error loading sub-centers: ' + error.message, 'error');
            if (subCenterSelect) {
                subCenterSelect.innerHTML = '<option value="">Error loading sub-centers</option>';
            }
        }
    });
}

if (subCenterSelect) {
    subCenterSelect.addEventListener('change', async function() {
        const subCenterId = this.value;
        selectedSubCenter = subCenterId;
        
        if (villageSelect) {
            villageSelect.innerHTML = '<option value="">Loading...</option>';
            villageSelect.disabled = true;
        }
        
        if (!subCenterId) {
            if (villageSelect) {
                villageSelect.innerHTML = '<option value="">Select Sub-Center first</option>';
            }
            return;
        }

        try {
            const response = await fetch(`/api/villages/by-subcenter/${subCenterId}`);
            const villages = await response.json();
            
            if (villageSelect) {
                villageSelect.innerHTML = '<option value="">Select Village</option>';
                villages.forEach(village => {
                    const option = document.createElement('option');
                    option.value = village.village_id;
                    option.textContent = village.name;
                    villageSelect.appendChild(option);
                });
                villageSelect.disabled = false;
                
                if (villages.length === 0) {
                    const villageHelper = document.getElementById('villageHelper');
                    if (villageHelper) {
                        villageHelper.textContent = 
                            'No villages found for this sub-center. Please contact administrator.';
                    }
                } else {
                    const villageHelper = document.getElementById('villageHelper');
                    if (villageHelper) {
                        villageHelper.textContent = '';
                    }
                }
            }
        } catch (error) {
            showMessage('Error loading villages: ' + error.message, 'error');
            if (villageSelect) {
                villageSelect.innerHTML = '<option value="">Error loading villages</option>';
            }
        }
    });
}

// Manage data dropdowns
const manageState = document.getElementById('manageState');
const manageDistrict = document.getElementById('manageDistrict');
const manageBlock = document.getElementById('manageBlock');

if (manageState) {
    manageState.addEventListener('change', async (e) => {
        const stateId = e.target.value;
        manageDistrict.innerHTML = '<option value="">Select District</option>';
        manageBlock.innerHTML = '<option value="">Select Block</option>';
        manageDistrict.disabled = true;
        manageBlock.disabled = true;
        
        const dataDisplay = document.getElementById('dataDisplay');
        if (dataDisplay) dataDisplay.innerHTML = '';
        
        if (stateId) {
            try {
                const response = await fetch(`/api/districts/${stateId}`);
                if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
                
                const districts = await response.json();
                
                districts.forEach(district => {
                    const option = document.createElement('option');
                    option.value = district.district_id;
                    option.textContent = district.name;
                    manageDistrict.appendChild(option);
                });
                
                manageDistrict.disabled = false;
                displayData('districts', districts);
            } catch (error) {
                showMessage('Error loading districts: ' + error.message, 'error');
            }
        }
    });
    
    manageDistrict.addEventListener('change', async (e) => {
        const districtId = e.target.value;
        manageBlock.innerHTML = '<option value="">Select Block</option>';
        manageBlock.disabled = true;
        
        if (districtId) {
            try {
                const response = await fetch(`/api/blocks/${districtId}`);
                if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
                
                const blocks = await response.json();
                
                blocks.forEach(block => {
                    const option = document.createElement('option');
                    option.value = block.block_id;
                    option.textContent = block.name;
                    manageBlock.appendChild(option);
                });
                
                manageBlock.disabled = false;
                displayData('blocks', blocks);
            } catch (error) {
                showMessage('Error loading blocks: ' + error.message, 'error');
            }
        }
    });
    
    manageBlock.addEventListener('change', async (e) => {
        const blockId = e.target.value;
        
        if (blockId) {
            try {
                const response = await fetch(`/api/villages?block_id=${blockId}`);
                if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
                
                const villages = await response.json();
                displayData('villages', villages);
            } catch (error) {
                showMessage('Error loading villages: ' + error.message, 'error');
            }
        }
    });
}

// Display data in table
function displayData(type, data) {
    const displayDiv = document.getElementById('dataDisplay');
    
    if (!displayDiv || data.length === 0) {
        if (displayDiv) displayDiv.innerHTML = '<p>No data found</p>';
        return;
    }
    
    let idField;
    if (type === 'districts') idField = 'district_id';
    else if (type === 'blocks') idField = 'block_id';
    else if (type === 'villages') idField = 'village_lgd_code';
    
    let html = `
        <table class="data-table">
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Name</th>
                    <th>Action</th>
                </tr>
            </thead>
            <tbody>
    `;
    
    data.forEach(item => {
        html += `
            <tr>
                <td>${item[idField]}</td>
                <td>${escapeHtml(item.name)}</td>
                <td>
                    <button class="btn btn-danger" onclick="deleteRecord('${type}', ${item[idField]})">Delete</button>
                </td>
            </tr>
        `;
    });
    
    html += '</tbody></table>';
    displayDiv.innerHTML = html;
}

// Delete record
async function deleteRecord(table, id) {
    if (!confirm('Are you sure you want to delete this record?')) {
        return;
    }
    
    try {
        const response = await fetch(`/api/admin/delete/${table}/${id}`, {
            method: 'DELETE'
        });
        
        if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
        
        const result = await response.json();
        
        if (result.success) {
            showMessage('✓ Record deleted successfully', 'success');
            
            // Reload appropriate view
            if (table === 'states') {
                loadAllStates();
                loadStatesForAllDropdowns();
            } else if (table === 'districts') {
                loadAllDistricts();
            } else if (table === 'blocks') {
                loadAllBlocks();
            } else if (table === 'villages') {
                loadAllVillages();
            }
            
            // Refresh manage view if active
            const manageState = document.getElementById('manageState');
            if (manageState && manageState.value) {
                manageState.dispatchEvent(new Event('change'));
            }
        } else {
            showMessage(`Error: ${result.error}`, 'error');
        }
    } catch (error) {
        showMessage('Error deleting record: ' + error.message, 'error');
    }
}

// ==================== LOCATION FORM SUBMISSIONS ====================

const addStateForm = document.getElementById('addStateForm');
if (addStateForm) {
    addStateForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        
        const formData = {
            name: e.target.querySelector('[name="name"]').value.trim(),
            territory_type: e.target.querySelector('[name="territory_type"]').value
        };
        
        if (!formData.name) {
            showMessage('State name is required', 'error');
            return;
        }
        
        try {
            const response = await fetch('/api/admin/state', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(formData)
            });
            
            if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
            
            const result = await response.json();
            
            if (result.success) {
                showMessage('✓ State added successfully', 'success');
                e.target.reset();
                loadStatesForAllDropdowns();
                loadAllStates();
            } else {
                showMessage(`Error: ${result.error}`, 'error');
            }
        } catch (error) {
            showMessage('Error adding state: ' + error.message, 'error');
        }
    });
}

const addDistrictForm = document.getElementById('addDistrictForm');
if (addDistrictForm) {
    addDistrictForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        
        const formData = {
            name: e.target.querySelector('[name="name"]').value.trim(),
            state_id: parseInt(e.target.querySelector('[name="state_id"]').value)
        };
        
        if (!formData.name || !formData.state_id) {
            showMessage('All fields are required', 'error');
            return;
        }
        
        try {
            const response = await fetch('/api/admin/district', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(formData)
            });
            
            if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
            
            const result = await response.json();
            
            if (result.success) {
                showMessage('✓ District added successfully', 'success');
                e.target.reset();
                loadAllDistricts();
            } else {
                showMessage(`Error: ${result.error}`, 'error');
            }
        } catch (error) {
            showMessage('Error adding district: ' + error.message, 'error');
        }
    });
}

if (addBlockForm) {
    addBlockForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        
        const formData = {
            name: e.target.querySelector('[name="name"]').value.trim(),
            district_id: parseInt(e.target.querySelector('[name="district_id"]').value)
        };
        
        if (!formData.name || !formData.district_id) {
            showMessage('All fields are required', 'error');
            return;
        }
        
        try {
            const response = await fetch('/api/admin/block', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(formData)
            });
            
            if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
            
            const result = await response.json();
            
            if (result.success) {
                showMessage('✓ Block added successfully', 'success');
                e.target.reset();
                document.getElementById('blockDistrict').disabled = true;
                loadAllBlocks();
            } else {
                showMessage(`Error: ${result.error}`, 'error');
            }
        } catch (error) {
            showMessage('Error adding block: ' + error.message, 'error');
        }
    });
}

if (addVillageForm) {
    addVillageForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        
        const formData = {
            village_lgd_code: parseInt(e.target.querySelector('[name="village_lgd_code"]').value),
            name: e.target.querySelector('[name="name"]').value.trim(),
            district_id: parseInt(e.target.querySelector('[name="district_id"]').value),
            block_id: parseInt(e.target.querySelector('[name="block_id"]').value)
        };
        
        if (!formData.name || !formData.district_id || !formData.block_id) {
            showMessage('All fields are required', 'error');
            return;
        }
        
        try {
            const response = await fetch('/api/admin/village', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(formData)
            });
            
            if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
            
            const result = await response.json();
            
            if (result.success) {
                showMessage('✓ Village added successfully', 'success');
                e.target.reset();
                document.getElementById('villageDistrict').disabled = true;
                document.getElementById('villageBlock').disabled = true;
                loadAllVillages();
            } else {
                showMessage(`Error: ${result.error}`, 'error');
            }
        } catch (error) {
            showMessage('Error adding village: ' + error.message, 'error');
        }
    });
}

// ==================== HOUSEHOLD MANAGEMENT ====================

// Load all households
async function loadHouseholds() {
    try {
        const response = await fetch('/api/admin/households');
        if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
        
        const households = await response.json();
        
        const householdsList = document.getElementById('householdsList');
        if (!householdsList) return;
        
        if (households.length === 0) {
            householdsList.innerHTML = '<div class="empty-state"><p>No households found.</p></div>';
            return;
        }
        
        let html = `
            <table class="data-table">
                <thead>
                    <tr>
                        <th>Household ID</th>
                        <th>Name</th>
                        <th>User</th>
                        <th>State</th>
                        <th>District</th>
                        <th>Block</th>
                        <th>Village</th>
                        <th>Created</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
        `;
        
        households.forEach(h => {
            const createdDate = new Date(h.created_at).toLocaleDateString();
            html += `
                <tr>
                    <td>${h.household_id}</td>
                    <td>${escapeHtml(h.household_name)}</td>
                    <td>${escapeHtml(h.username || 'N/A')}</td>
                    <td>${escapeHtml(h.state_name || 'N/A')}</td>
                    <td>${escapeHtml(h.district_name || 'N/A')}</td>
                    <td>${escapeHtml(h.block_name || 'N/A')}</td>
                    <td>${escapeHtml(h.village_name || 'N/A')}</td>
                    <td>${createdDate}</td>
                    <td>
                        <button class="btn btn-edit" onclick="viewHouseholdDetails(${h.household_id})">View</button>
                        <button class="btn btn-danger" onclick="deleteHousehold(${h.household_id})">Delete</button>
                    </td>
                </tr>
            `;
        });
        
        html += '</tbody></table>';
        householdsList.innerHTML = html;
    } catch (error) {
        showMessage('Error loading households: ' + error.message, 'error');
    }
}

// View household details and responses
async function viewHouseholdDetails(householdId) {
    try {
        const householdResponse = await fetch(`/api/admin/household/${householdId}`);
        if (!householdResponse.ok) throw new Error(`HTTP error! status: ${householdResponse.status}`);
        
        const household = await householdResponse.json();
        
        const responsesResponse = await fetch(`/api/admin/household/${householdId}/responses`);
        if (!responsesResponse.ok) throw new Error(`HTTP error! status: ${responsesResponse.status}`);
        
        const responses = await responsesResponse.json();
        
        let detailHtml = `
            <div style="margin-bottom: 30px;">
                <h3>Household Details</h3>
                <table class="data-table">
                    <tr>
                        <th>Household ID</th>
                        <td>${household.household_id}</td>
                    </tr>
                    <tr>
                        <th>Name</th>
                        <td>${escapeHtml(household.household_name)}</td>
                    </tr>
                    <tr>
                        <th>User</th>
                        <td>${escapeHtml(household.username || 'N/A')}</td>
                    </tr>
                    <tr>
                        <th>Location</th>
                        <td>${escapeHtml(household.state_name || 'N/A')} → ${escapeHtml(household.district_name || 'N/A')} → ${escapeHtml(household.block_name || 'N/A')} → ${escapeHtml(household.village_name || 'N/A')}</td>
                    </tr>
                    <tr>
                        <th>Created</th>
                        <td>${new Date(household.created_at).toLocaleString()}</td>
                    </tr>
                </table>
            </div>
        `;
        
        if (responses.length > 0) {
            detailHtml += `
                <h3>Questionnaire Responses (${responses.length})</h3>
                <table class="data-table">
                    <thead>
                        <tr>
                            <th>Section</th>
                            <th>Question</th>
                            <th>Answer</th>
                            <th>Type</th>
                        </tr>
                    </thead>
                    <tbody>
            `;
            
            responses.forEach(r => {
                const answer = r.answer_text || r.answer_numerical || 'No answer';
                detailHtml += `
                    <tr>
                        <td>${escapeHtml(r.section_title)}</td>
                        <td>${escapeHtml(r.question_text)}</td>
                        <td>${escapeHtml(String(answer))}</td>
                        <td>${r.question_type}</td>
                    </tr>
                `;
            });
            
            detailHtml += '</tbody></table>';
        } else {
            detailHtml += '<p>No responses submitted yet.</p>';
        }
        
        const householdsList = document.getElementById('householdsList');
        if (householdsList) {
            householdsList.innerHTML = detailHtml + '<button class="btn btn-secondary" onclick="loadHouseholds()">Back to List</button>';
        }
    } catch (error) {
        showMessage('Error loading household details: ' + error.message, 'error');
    }
}

// Delete household
async function deleteHousehold(householdId) {
    if (!confirm('Are you sure? This will delete the household and all its responses!')) {
        return;
    }
    
    try {
        const response = await fetch(`/api/admin/household/${householdId}`, {
            method: 'DELETE'
        });
        
        if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
        
        const result = await response.json();
        
        if (result.success) {
            showMessage('✓ Household deleted successfully', 'success');
            loadHouseholds();
        } else {
            showMessage(`Error: ${result.error}`, 'error');
        }
    } catch (error) {
        showMessage('Error deleting household: ' + error.message, 'error');
    }
}

// ==================== SUB-CENTER MANAGEMENT ====================

function displayBrowseSubCenters(subCenters) {
    const container = document.getElementById('subCentersList');
    if (!container) return;
    
    if (subCenters.length === 0) {
        container.innerHTML = '<div class="empty-state">No sub-centers found</div>';
        return;
    }

    let html = '';
    subCenters.forEach(sc => {
        html += `
            <div class="location-item" onclick="selectSubCenter(${sc.sub_center_id})">
                <span class="location-name">${escapeHtml(sc.name)}</span>
                <div class="location-actions">
                    <button class="btn btn-edit" onclick="event.stopPropagation(); editSubCenter(${sc.sub_center_id}, '${escapeHtml(sc.name).replace(/'/g, "\\'")}', ${sc.block_id})">Edit</button>
                    <button class="btn btn-danger" onclick="event.stopPropagation(); deleteSubCenter(${sc.sub_center_id})">Delete</button>
                </div>
            </div>
        `;
    });
    container.innerHTML = html;
}

function filterBrowseSubCenters() {
    const search = document.getElementById('browseSubCenterSearch').value.toLowerCase();
    const filtered = browseSubCenters.filter(sc => sc.name.toLowerCase().includes(search));
    displayBrowseSubCenters(filtered);
}

async function selectSubCenter(subCenterId) {
    selectedSubCenterId = subCenterId;
    
    try {
        const response = await apiFetch(`/api/villages/by-subcenter/${subCenterId}`);
        const villages = await response.json();
        browseVillages = villages;
        displayBrowseVillages(villages);
    } catch (error) {
        showMessage('Error loading villages: ' + error.message, 'error');
    }
}

async function loadSubCenterDistricts() {
    const stateId = document.getElementById('subCenterState').value;
    const districtEl = document.getElementById('subCenterDistrict');
    const blockEl = document.getElementById('subCenterBlock');
    
    districtEl.innerHTML = '<option value="">Loading...</option>';
    districtEl.disabled = true;
    blockEl.innerHTML = '<option value="">Select District first</option>';
    blockEl.disabled = true;
    
    if (!stateId) {
        districtEl.innerHTML = '<option value="">Select State first</option>';
        return;
    }
    
    try {
        const response = await apiFetch(`/api/districts/${stateId}`);
        const districts = await response.json();
        
        districtEl.innerHTML = '<option value="">Select District</option>';
        districts.forEach(d => {
            const option = document.createElement('option');
            option.value = d.district_id;
            option.textContent = d.name;
            districtEl.appendChild(option);
        });
        districtEl.disabled = false;
    } catch (error) {
        showMessage('Error loading districts: ' + error.message, 'error');
    }
}

async function loadSubCenterBlocks() {
    const districtId = document.getElementById('subCenterDistrict').value;
    const blockEl = document.getElementById('subCenterBlock');
    
    blockEl.innerHTML = '<option value="">Loading...</option>';
    blockEl.disabled = true;
    
    if (!districtId) {
        blockEl.innerHTML = '<option value="">Select District first</option>';
        return;
    }
    
    try {
        const response = await apiFetch(`/api/blocks/${districtId}`);
        const blocks = await response.json();
        
        blockEl.innerHTML = '<option value="">Select Block</option>';
        blocks.forEach(b => {
            const option = document.createElement('option');
            option.value = b.block_id;
            option.textContent = b.name;
            blockEl.appendChild(option);
        });
        blockEl.disabled = false;
    } catch (error) {
        showMessage('Error loading blocks: ' + error.message, 'error');
    }
}

async function addSubCenter() {
    const blockId = document.getElementById('subCenterBlock').value;
    const name = document.getElementById('subCenterName').value.trim();
    
    if (!blockId || !name) {
        showMessage('All fields are required', 'error');
        return;
    }

    try {
        const response = await apiFetch('/api/admin/sub-center', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ name, block_id: parseInt(blockId) })
        });
        const result = await response.json();
        
        if (result.success) {
            showMessage('Sub-center added successfully', 'success');
            document.getElementById('subCenterName').value = '';
            if (selectedBlockId) selectBlock(selectedBlockId);
        } else {
            showMessage(result.error || 'Failed to add sub-center', 'error');
        }
    } catch (error) {
        showMessage('Error: ' + error.message, 'error');
    }
}

function editSubCenter(id, name, blockId) {
    apiFetch('/api/admin/all-blocks').then(r => r.json()).then(blocks => {
        editingData = { type: 'subcenter', id };
        document.getElementById('editModalTitle').textContent = 'Edit Sub-Center';
        document.getElementById('editFormContent').innerHTML = `
            <div class="form-group">
                <label>Block *</label>
                <select id="editBlock" required>${blocks.map(b => `<option value="${b.block_id}" ${b.block_id === blockId ? 'selected' : ''}>${escapeHtml(b.name)}</option>`).join('')}</select>
            </div>
            <div class="form-group">
                <label>Sub-Center Name *</label>
                <input type="text" id="editName" value="${escapeHtml(name)}" required>
            </div>
        `;
        document.getElementById('editForm').onsubmit = async (e) => {
            e.preventDefault();
            const blockId = parseInt(document.getElementById('editBlock').value);
            const name = document.getElementById('editName').value.trim();
            
            try {
                const response = await apiFetch(`/api/admin/sub-center/${id}`, {
                    method: 'PUT',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ name, block_id: blockId })
                });
                const result = await response.json();
                
                if (result.success) {
                    showMessage('Sub-center updated successfully', 'success');
                    closeModal();
                    if (selectedBlockId) selectBlock(selectedBlockId);
                } else {
                    showMessage(result.error || 'Failed to update sub-center', 'error');
                }
            } catch (error) {
                showMessage('Error: ' + error.message, 'error');
            }
        };
        document.getElementById('editModal').classList.add('show');
    });
}

async function deleteSubCenter(id) {
    if (!confirm('Delete this sub-center?')) return;
    
    try {
        const response = await apiFetch(`/api/admin/sub-center/${id}`, {
            method: 'DELETE'
        });
        const result = await response.json();
        
        if (result.success) {
            showMessage('Sub-center deleted successfully', 'success');
            if (selectedBlockId) selectBlock(selectedBlockId);
        } else {
            showMessage(result.error || 'Failed to delete sub-center', 'error');
        }
    } catch (error) {
        showMessage('Error: ' + error.message, 'error');
    }
}

// ==================== STATISTICS DASHBOARD ====================

// Load and display statistics
async function loadStatistics() {
    try {
        const response = await fetch('/api/admin/statistics');
        if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
        
        const stats = await response.json();
        
        const statisticsDiv = document.getElementById('statisticsList');
        if (!statisticsDiv) return;
        
        const html = `
            <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin: 20px 0;">
                <div class="stat-card" style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; border-radius: 8px; text-align: center;">
                    <p style="font-size: 2em; font-weight: bold;">${stats.total_users}</p>
                    <p>Total Users</p>
                </div>
                <div class="stat-card" style="background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%); color: white; padding: 20px; border-radius: 8px; text-align: center;">
                    <p style="font-size: 2em; font-weight: bold;">${stats.total_households}</p>
                    <p>Total Households</p>
                </div>
                <div class="stat-card" style="background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%); color: white; padding: 20px; border-radius: 8px; text-align: center;">
                    <p style="font-size: 2em; font-weight: bold;">${stats.total_states}</p>
                    <p>States</p>
                </div>
                <div class="stat-card" style="background: linear-gradient(135deg, #43e97b 0%, #38f9d7 100%); color: white; padding: 20px; border-radius: 8px; text-align: center;">
                    <p style="font-size: 2em; font-weight: bold;">${stats.total_districts}</p>
                    <p>Districts</p>
                </div>
                <div class="stat-card" style="background: linear-gradient(135deg, #fa709a 0%, #fee140 100%); color: white; padding: 20px; border-radius: 8px; text-align: center;">
                    <p style="font-size: 2em; font-weight: bold;">${stats.total_sections}</p>
                    <p>Question Sections</p>
                </div>
                <div class="stat-card" style="background: linear-gradient(135deg, #30cfd0 0%, #330867 100%); color: white; padding: 20px; border-radius: 8px; text-align: center;">
                    <p style="font-size: 2em; font-weight: bold;">${stats.total_questions}</p>
                    <p>Questions</p>
                </div>
                <div class="stat-card" style="background: linear-gradient(135deg, #a8edea 0%, #fed6e3 100%); color: #333; padding: 20px; border-radius: 8px; text-align: center;">
                    <p style="font-size: 2em; font-weight: bold;">${stats.total_responses}</p>
                    <p>Responses</p>
                </div>
            </div>
        `;
        
        statisticsDiv.innerHTML = html;
    } catch (error) {
        showMessage('Error loading statistics: ' + error.message, 'error');
    }
}

// ==================== UTILITY FUNCTIONS ====================

function openModal(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) {
        modal.classList.add('show');
    }
}

function closeModal(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) {
        modal.classList.remove('show');
    }
}

function showMessage(text, type) {
    const messageDiv = document.getElementById('adminMessage');
    if (!messageDiv) return;
    
    messageDiv.textContent = text;
    messageDiv.className = `message ${type} show`;
    
    setTimeout(() => {
        messageDiv.classList.remove('show');
    }, 4000);
}

function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

// ==================== MODAL CLOSE ON BACKGROUND CLICK ====================

document.addEventListener('click', (e) => {
    const modals = document.querySelectorAll('.modal.show');
    modals.forEach(modal => {
        if (e.target === modal) {
            closeModal(modal.id);
        }
    });
});