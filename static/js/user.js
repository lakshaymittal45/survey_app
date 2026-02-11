// ==================== GLOBAL STATE ====================

let questionnaireData = null;
let currentResponses = {};
let currentSectionIndex = 0;

// ==================== DOM ELEMENTS ====================

const questionnaireContainer = document.getElementById('questionnaireContainer');
const sectionTitle = document.getElementById('sectionTitle');
const questionsContainer = document.getElementById('questionsContainer');
const prevBtn = document.getElementById('prevBtn');
const nextBtn = document.getElementById('nextBtn');
const submitBtn = document.getElementById('submitBtn');
const messageDiv = document.getElementById('message');
const progressBar = document.getElementById('progressBar');
const sectionProgress = document.getElementById('sectionProgress');

// ==================== PAGE INITIALIZATION ====================

document.addEventListener('DOMContentLoaded', async () => {
    await loadQuestionnaireData();
    displayCurrentSection();
    setupNavigation();
});

// ==================== LOAD QUESTIONNAIRE DATA ====================

async function loadQuestionnaireData() {
    try {
        showMessage('Loading questionnaire...', 'info');
        
        const response = await fetch('/api/questionnaire/data');
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        
        const data = await response.json();
        
        if (!data.sections || data.sections.length === 0) {
            showMessage('No questionnaire sections available. Please contact administrator.', 'error');
            questionnaireContainer.innerHTML = '<div class="error-state"><p>No questionnaire available. Please contact your administrator.</p></div>';
            return;
        }
        
        questionnaireData = data;
        
        // Load existing responses if available
        loadExistingResponses();
        
        hideMessage();
    } catch (error) {
        console.error('Error loading questionnaire:', error);
        showMessage(`Error loading questionnaire: ${error.message}`, 'error');
        questionnaireContainer.innerHTML = '<div class="error-state"><p>Failed to load questionnaire. Please try refreshing the page.</p></div>';
    }
}

// ==================== LOAD EXISTING RESPONSES ====================

function loadExistingResponses() {
    if (!questionnaireData || !questionnaireData.sections) return;
    
    questionnaireData.sections.forEach(section => {
        section.questions.forEach(question => {
            if (question.existing && question.existing.answer !== null && question.existing.answer !== undefined) {
                currentResponses[question.question_id] = question.existing.answer;
            }
        });
    });
}

// ==================== DISPLAY SECTION ====================

function displayCurrentSection() {
    if (!questionnaireData || !questionnaireData.sections) return;
    
    const section = questionnaireData.sections[currentSectionIndex];
    
    if (!section) {
        showMessage('Section not found', 'error');
        return;
    }
    
    // Update section title
    sectionTitle.textContent = section.section_title;
    
    // Update progress
    updateProgress();
    
    // Clear questions container
    questionsContainer.innerHTML = '';
    
    // Display questions
    section.questions.forEach((question, index) => {
        const questionDiv = createQuestionElement(question, index + 1);
        questionsContainer.appendChild(questionDiv);
    });
    
    // Update navigation buttons
    updateNavigationButtons();
    
    // Scroll to top
    window.scrollTo(0, 0);
}

// ==================== CREATE QUESTION ELEMENT ====================

function createQuestionElement(question, questionNumber) {
    const questionDiv = document.createElement('div');
    questionDiv.className = 'question-item';
    questionDiv.dataset.questionId = question.question_id;
    
    // Question text
    const questionText = document.createElement('label');
    questionText.className = 'question-label';
    questionText.innerHTML = `<span class="question-number">${questionNumber}.</span> ${escapeHtml(question.question_text)}`;
    questionDiv.appendChild(questionText);
    
    // Get existing answer
    const existingAnswer = currentResponses[question.question_id];
    
    // Answer input based on question type and answer type
    let answerElement;
    
    if (question.options && question.options.length > 0) {
        // Determine input type: single_choice -> radio, multiple_choice -> checkbox
        const isMultiple = question.question_type === 'multiple_choice';
        const optionsContainer = document.createElement('div');
        optionsContainer.className = 'options-container';

        // Find child questions (same section) that reference this question as parent
        const currentSection = questionnaireData.sections[currentSectionIndex] || { questions: [] };
        const childQuestions = (currentSection.questions || []).filter(q => q.parent_id === question.question_id);
        const childContainer = document.createElement('div');
        childContainer.className = 'child-questions';
        childContainer.style.display = 'none';

        // (Removed per-option wrapper map; child questions rebuilt dynamically)

        // (Removed helper: subtree response clearing is handled during rebuild)

        question.options.forEach(option => {
            const optionDiv = document.createElement('div');
            optionDiv.className = 'option-item';

            const input = document.createElement('input');
            input.type = isMultiple ? 'checkbox' : 'radio';
            input.name = `question_${question.question_id}` + (isMultiple ? `_${option.option_id}` : '');
            input.value = String(option.option_id);
            input.id = `option_${option.option_id}`;

            if (isMultiple && Array.isArray(existingAnswer) && (existingAnswer.includes(String(option.option_id)) || existingAnswer.includes(option.option_text))) {
                input.checked = true;
            } else if (!isMultiple && (String(existingAnswer) === String(option.option_id) || existingAnswer === option.option_text)) {
                input.checked = true;
            }

            input.addEventListener('change', () => {

                if (isMultiple) {
                    const arr = Array.isArray(currentResponses[question.question_id])
                        ? currentResponses[question.question_id].slice()
                        : [];

                    const value = String(option.option_id);

                    if (input.checked) {
                        if (!arr.includes(value)) arr.push(value);
                    } else {
                        const idx = arr.indexOf(value);
                        if (idx !== -1) arr.splice(idx, 1);
                    }

                    currentResponses[question.question_id] = arr;
                } else {
                    currentResponses[question.question_id] = String(option.option_id);
                }

                // 🔥 CLEAN REBUILD CHILDREN
                if (childQuestions && childQuestions.length > 0) {

                    const activeValues = isMultiple
                        ? (currentResponses[question.question_id] || [])
                        : [currentResponses[question.question_id]];

                    // Clear previous children completely
                    childContainer.innerHTML = '';

                    childQuestions.forEach((child, idx) => {

                        if (activeValues.includes(String(child.trigger_value))) {

                            const childEl = createQuestionElement(
                                child,
                                `${questionNumber}.${idx + 1}`
                            );

                            childContainer.appendChild(childEl);
                        } else {
                            // Also clear response if not active
                            delete currentResponses[child.question_id];
                        }
                    });

                    childContainer.style.display =
                        childContainer.children.length > 0 ? '' : 'none';
                }

                saveProgress();
            });

            const label = document.createElement('label');
            label.htmlFor = `option_${option.option_id}`;
            label.textContent = option.option_text;

            optionDiv.appendChild(input);
            optionDiv.appendChild(label);
            optionsContainer.appendChild(optionDiv);
        });

        // (Child question elements are created dynamically when options change)

        // Initialize child visibility
        if (childQuestions.length > 0) {

            const activeValues = isMultiple
                ? (Array.isArray(existingAnswer) ? existingAnswer : [])
                : [existingAnswer];

            childQuestions.forEach((child, idx) => {
                if (activeValues.includes(String(child.trigger_value))) {
                    const childEl = createQuestionElement(
                        child,
                        `${questionNumber}.${idx + 1}`
                    );
                    childContainer.appendChild(childEl);
                }
            });

            childContainer.style.display =
                childContainer.children.length > 0 ? '' : 'none';
        }

        answerElement = document.createElement('div');
        answerElement.appendChild(optionsContainer);
        if (childQuestions.length > 0) answerElement.appendChild(childContainer);
        
    } else if (question.answer_type === 'numerical') {
        // Numerical input
        answerElement = document.createElement('input');
        answerElement.type = 'number';
        answerElement.className = 'answer-input';
        answerElement.placeholder = 'Enter number';
        
        if (existingAnswer !== null && existingAnswer !== undefined) {
            answerElement.value = existingAnswer;
        }
        
        answerElement.addEventListener('input', (e) => {
            const value = e.target.value;
            currentResponses[question.question_id] = value ? parseFloat(value) : null;
            saveProgress();
        });
        
    } else {
        // Text input (default)
        answerElement = document.createElement('textarea');
        answerElement.className = 'answer-textarea';
        answerElement.rows = 3;
        answerElement.placeholder = 'Enter your answer';
        
        if (existingAnswer !== null && existingAnswer !== undefined) {
            answerElement.value = existingAnswer;
        }
        
        answerElement.addEventListener('input', (e) => {
            currentResponses[question.question_id] = e.target.value;
            saveProgress();
        });
    }
    
    questionDiv.appendChild(answerElement);
    
    return questionDiv;
}

// ==================== NAVIGATION ====================

function setupNavigation() {
    if (prevBtn) {
        prevBtn.addEventListener('click', () => {
            if (currentSectionIndex > 0) {
                currentSectionIndex--;
                displayCurrentSection();
            }
        });
    }
    
    if (nextBtn) {
        nextBtn.addEventListener('click', () => {
            if (currentSectionIndex < questionnaireData.sections.length - 1) {
                currentSectionIndex++;
                displayCurrentSection();
            }
        });
    }
    
    if (submitBtn) {
        submitBtn.addEventListener('click', async () => {
            await submitQuestionnaire();
        });
    }
}

function updateNavigationButtons() {
    if (!questionnaireData) return;
    
    // Previous button
    if (prevBtn) {
        prevBtn.disabled = currentSectionIndex === 0;
        prevBtn.style.display = currentSectionIndex === 0 ? 'none' : 'inline-block';
    }
    
    // Next button
    if (nextBtn) {
        const isLastSection = currentSectionIndex === questionnaireData.sections.length - 1;
        nextBtn.style.display = isLastSection ? 'none' : 'inline-block';
    }
    
    // Submit button
    if (submitBtn) {
        const isLastSection = currentSectionIndex === questionnaireData.sections.length - 1;
        submitBtn.style.display = isLastSection ? 'inline-block' : 'none';
    }
}

function updateProgress() {
    if (!questionnaireData) return;
    
    const totalSections = questionnaireData.sections.length;
    const currentSection = currentSectionIndex + 1;
    const progressPercentage = (currentSection / totalSections) * 100;
    
    if (progressBar) {
        progressBar.style.width = `${progressPercentage}%`;
    }
    
    if (sectionProgress) {
        sectionProgress.textContent = `Section ${currentSection} of ${totalSections}`;
    }
}

// ==================== SAVE PROGRESS ====================

async function saveProgress() {
    // Auto-save responses in the background
    try {
        const response = await fetch('/api/save_responses', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                responses: currentResponses
            })
        });
        
        if (!response.ok) {
            console.error('Failed to save progress');
        }
    } catch (error) {
        console.error('Error saving progress:', error);
    }
}

// ==================== SUBMIT QUESTIONNAIRE ====================

async function submitQuestionnaire() {
    if (!confirm('Are you sure you want to submit? You can review and edit your answers later.')) {
        return;
    }
    
    try {
        submitBtn.disabled = true;
        submitBtn.innerHTML = '<span class="loading-spinner"></span>Submitting...';
        
        const response = await fetch('/api/save_responses', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                responses: currentResponses
            })
        });
        
        const result = await response.json();
        
        if (!response.ok) {
            throw new Error(result.error || `HTTP error! status: ${response.status}`);
        }
        
        if (result.success) {
            showMessage('✓ Questionnaire submitted successfully!', 'success');
            
            // Redirect to dashboard after 2 seconds
            setTimeout(() => {
                window.location.href = '/user-dashboard';
            }, 2000);
        } else {
            throw new Error(result.error || 'Submission failed');
        }
    } catch (error) {
        console.error('Error submitting questionnaire:', error);
        showMessage(`Error submitting questionnaire: ${error.message}`, 'error');
        submitBtn.disabled = false;
        submitBtn.innerHTML = 'Submit Questionnaire';
    }
}

// ==================== UTILITY FUNCTIONS ====================

function showMessage(text, type) {
    if (!messageDiv) return;
    
    messageDiv.textContent = text;
    messageDiv.className = `message ${type}`;
    messageDiv.style.display = 'block';
    
    // Auto-hide success/info messages after 5 seconds
    if (type === 'success' || type === 'info') {
        setTimeout(() => {
            hideMessage();
        }, 5000);
    }
}

function hideMessage() {
    if (messageDiv) {
        messageDiv.style.display = 'none';
    }
}

function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

// ==================== KEYBOARD NAVIGATION ====================

document.addEventListener('keydown', (e) => {
    // Navigate with arrow keys (only if not typing in input)
    if (e.target.tagName !== 'INPUT' && e.target.tagName !== 'TEXTAREA') {
        if (e.key === 'ArrowLeft' && prevBtn && !prevBtn.disabled) {
            prevBtn.click();
        } else if (e.key === 'ArrowRight' && nextBtn && !nextBtn.disabled) {
            nextBtn.click();
        }
    }
});

// ==================== AUTO-SAVE ON PAGE UNLOAD ====================

window.addEventListener('beforeunload', (e) => {
    // Save progress before leaving
    if (Object.keys(currentResponses).length > 0) {
        saveProgress();
    }
});