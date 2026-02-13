// ===============================================
// SHARED LOCATION MANAGEMENT MODULE
// For use in admin_dashboard.html and survey_locations.html
// ===============================================

const LocationManager = {
    // State management
    data: {
        allStates: [],
        allDistricts: [],
        allBlocks: [],
        allSubCenters: [],
        allVillages: []
    },

    // Initialize location dropdowns
    async initializeDropdowns() {
        try {
            const [statesRes, districtsRes] = await Promise.all([
                fetch('/api/admin/all-states'),
                fetch('/api/admin/all-districts')
            ]);
            
            if (!statesRes.ok || !districtsRes.ok) {
                throw new Error('Failed to load initial location data');
            }
            
            this.data.allStates = await statesRes.json();
            this.data.allDistricts = await districtsRes.json();
            
            return true;
        } catch (error) {
            console.error('Error initializing dropdowns:', error);
            showMessage('Error loading location data: ' + error.message, 'error');
            return false;
        }
    },

    // Populate state dropdown
    populateStates(selectId) {
        const select = document.getElementById(selectId);
        if (!select) return;
        
        select.innerHTML = '<option value="">Select State</option>';
        this.data.allStates.forEach(state => {
            const option = document.createElement('option');
            option.value = state.state_id;
            option.textContent = state.name;
            select.appendChild(option);
        });
    },

    // Get districts for state
    async loadDistricts(stateId, selectId) {
        const select = document.getElementById(selectId);
        if (!select) return;
        
        select.innerHTML = '<option value="">Loading...</option>';
        select.disabled = true;
        
        if (!stateId) {
            select.innerHTML = '<option value="">Select State first</option>';
            return;
        }
        
        try {
            const response = await fetch(`/api/districts/${stateId}`);
            if (!response.ok) throw new Error('Failed to load districts');
            
            const districts = await response.json();
            select.innerHTML = '<option value="">Select District</option>';
            districts.forEach(d => {
                const option = document.createElement('option');
                option.value = d.district_id;
                option.textContent = d.name;
                select.appendChild(option);
            });
            select.disabled = false;
        } catch (error) {
            showMessage('Error loading districts: ' + error.message, 'error');
            select.innerHTML = '<option value="">Error loading districts</option>';
        }
    },

    // Get blocks for district
    async loadBlocks(districtId, selectId) {
        const select = document.getElementById(selectId);
        if (!select) return;
        
        select.innerHTML = '<option value="">Loading...</option>';
        select.disabled = true;
        
        if (!districtId) {
            select.innerHTML = '<option value="">Select District first</option>';
            return;
        }
        
        try {
            const response = await fetch(`/api/blocks/${districtId}`);
            if (!response.ok) throw new Error('Failed to load blocks');
            
            const blocks = await response.json();
            select.innerHTML = '<option value="">Select Block</option>';
            blocks.forEach(b => {
                const option = document.createElement('option');
                option.value = b.block_id;
                option.textContent = b.name;
                select.appendChild(option);
            });
            select.disabled = false;
        } catch (error) {
            showMessage('Error loading blocks: ' + error.message, 'error');
            select.innerHTML = '<option value="">Error loading blocks</option>';
        }
    },

    // Get sub-centers for block
    async loadSubCenters(blockId, selectId) {
        const select = document.getElementById(selectId);
        if (!select) return;
        
        select.innerHTML = '<option value="">Loading...</option>';
        select.disabled = true;
        
        if (!blockId) {
            select.innerHTML = '<option value="">Select Block first</option>';
            return;
        }
        
        try {
            const response = await fetch(`/api/sub-centers/${blockId}`);
            if (!response.ok) throw new Error('Failed to load sub-centers');
            
            const subcenters = await response.json();
            select.innerHTML = '<option value="">Select Sub-Center</option>';
            subcenters.forEach(sc => {
                const option = document.createElement('option');
                option.value = sc.sub_center_id;
                option.textContent = sc.name;
                select.appendChild(option);
            });
            select.disabled = false;
        } catch (error) {
            showMessage('Error loading sub-centers: ' + error.message, 'error');
            select.innerHTML = '<option value="">Error loading sub-centers</option>';
        }
    },

    // Get villages for sub-center
    async loadVillages(subCenterId, selectId) {
        const select = document.getElementById(selectId);
        if (!select) return;
        
        select.innerHTML = '<option value="">Loading...</option>';
        select.disabled = true;
        
        if (!subCenterId) {
            select.innerHTML = '<option value="">Select Sub-Center first</option>';
            return;
        }
        
        try {
            const response = await fetch(`/api/villages/by-subcenter/${subCenterId}`);
            if (!response.ok) throw new Error('Failed to load villages');
            
            const villages = await response.json();
            select.innerHTML = '<option value="">Select Village</option>';
            villages.forEach(v => {
                const option = document.createElement('option');
                option.value = v.village_id;
                option.textContent = v.name;
                select.appendChild(option);
            });
            select.disabled = false;
        } catch (error) {
            showMessage('Error loading villages: ' + error.message, 'error');
            select.innerHTML = '<option value="">Error loading villages</option>';
        }
    },

    // Add new state
    async addState(name, territoryType = 'STATE') {
        try {
            if (!name || !name.trim()) {
                showMessage('State name is required', 'error');
                return false;
            }
            
            const response = await fetch('/api/admin/state', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    name: name.trim(),
                    territory_type: territoryType
                })
            });
            
            const result = await response.json();
            if (response.ok && result.success) {
                showMessage('✓ State added successfully', 'success');
                // Reload states
                const statesRes = await fetch('/api/admin/all-states');
                this.data.allStates = await statesRes.json();
                return true;
            } else {
                showMessage(result.error || 'Failed to add state', 'error');
                return false;
            }
        } catch (error) {
            showMessage('Error: ' + error.message, 'error');
            return false;
        }
    },

    // Add new district
    async addDistrict(name, stateId) {
        try {
            if (!name || !name.trim() || !stateId) {
                showMessage('District name and state are required', 'error');
                return false;
            }
            
            const response = await fetch('/api/admin/district', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    name: name.trim(),
                    state_id: parseInt(stateId)
                })
            });
            
            const result = await response.json();
            if (response.ok && result.success) {
                showMessage('✓ District added successfully', 'success');
                return true;
            } else {
                showMessage(result.error || 'Failed to add district', 'error');
                return false;
            }
        } catch (error) {
            showMessage('Error: ' + error.message, 'error');
            return false;
        }
    },

    // Add new block
    async addBlock(name, districtId) {
        try {
            if (!name || !name.trim() || !districtId) {
                showMessage('Block name and district are required', 'error');
                return false;
            }
            
            const response = await fetch('/api/admin/block', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    name: name.trim(),
                    district_id: parseInt(districtId)
                })
            });
            
            const result = await response.json();
            if (response.ok && result.success) {
                showMessage('✓ Block added successfully', 'success');
                return true;
            } else {
                showMessage(result.error || 'Failed to add block', 'error');
                return false;
            }
        } catch (error) {
            showMessage('Error: ' + error.message, 'error');
            return false;
        }
    },

    // Add new sub-center
    async addSubCenter(name, blockId) {
        try {
            if (!name || !name.trim() || !blockId) {
                showMessage('Sub-center name and block are required', 'error');
                return false;
            }
            
            const response = await fetch('/api/admin/sub-center', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    name: name.trim(),
                    block_id: parseInt(blockId)
                })
            });
            
            const result = await response.json();
            if (response.ok && result.success) {
                showMessage('✓ Sub-center added successfully', 'success');
                return true;
            } else {
                showMessage(result.error || 'Failed to add sub-center', 'error');
                return false;
            }
        } catch (error) {
            showMessage('Error: ' + error.message, 'error');
            return false;
        }
    },

    // Add new village
    async addVillage(lgdCode, name, subCenterId) {
        try {
            if (!lgdCode || !name || !name.trim() || !subCenterId) {
                showMessage('LGD code, name, and sub-center are required', 'error');
                return false;
            }
            
            const response = await fetch('/api/admin/village', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    village_lgd_code: parseInt(lgdCode),
                    name: name.trim(),
                    sub_center_id: parseInt(subCenterId)
                })
            });
            
            const result = await response.json();
            if (response.ok && result.success) {
                showMessage('✓ Village added successfully', 'success');
                return true;
            } else {
                showMessage(result.error || 'Failed to add village', 'error');
                return false;
            }
        } catch (error) {
            showMessage('Error: ' + error.message, 'error');
            return false;
        }
    },

    // Delete location by type
    async deleteLocation(type, id) {
        try {
            const response = await fetch(`/api/admin/${type}/${id}`, {
                method: 'DELETE'
            });
            
            const result = await response.json();
            if (response.ok && result.success) {
                showMessage('✓ Record deleted successfully', 'success');
                return true;
            } else {
                showMessage(result.error || 'Failed to delete', 'error');
                return false;
            }
        } catch (error) {
            showMessage('Error: ' + error.message, 'error');
            return false;
        }
    }
};

// Global message display function (should exist in page)
function showMessage(text, type) {
    const messageDiv = document.getElementById('message');
    if (!messageDiv) return;
    
    messageDiv.textContent = text;
    messageDiv.className = `message ${type} show`;
    
    setTimeout(() => {
        messageDiv.classList.remove('show');
    }, 4000);
}