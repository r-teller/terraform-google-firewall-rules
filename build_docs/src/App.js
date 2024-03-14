import React, { useState, useEffect, useCallback } from 'react';
import Form from '@rjsf/core';
import Ajv from 'ajv';
import validator from '@rjsf/validator-ajv8';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { faCopy, faEye, faBook, faShareAlt, faToggleOn, faToggleOff } from '@fortawesome/free-solid-svg-icons';
import firewallRulesRawSchema from './schemas/JSONSchema.json';
import firewallRulesUISchema from './schemas/UISchema.json';
import './modal.css';
import './main.css';
import './firewall-rules.css';
import 'bootstrap/dist/css/bootstrap.min.css';

// Initialize AJV with options suitable for your needs
const ajv = new Ajv({ strict: true, allErrors: true, useDefaults: true });
const addFormats = require("ajv-formats")
addFormats(ajv, ["email"])
const validate = ajv.compile(firewallRulesRawSchema);

const schema = {
  type: "object",
  properties: {
    firewall_rules: firewallRulesRawSchema
  }
};



function DescriptionFieldTemplate(props) {
  return null; // Ensure you have a valid return for all your components, even if null
}

function formatErrors(errors) {
  return errors
    .filter(error => error.keyword !== 'const' && error.keyword !== 'x') // Good practice to filter out unnecessary errors
    .map(error => `${error.instancePath} => ${error.schemaPath}`)
    .join('\n'); // Joining errors with newline for better readability
}

function App() {
  const [formData, setFormData] = useState({});
  const [showModal, setShowModal] = useState(false);
  const [isInputValid, setIsInputValid] = useState(true);
  const [liveValidate, setLiveValidate] = useState(true);
  const [validateSchema, setValidateSchema] = useState(true);
  const [modalInputData, setModalInputData] = useState("");
  const [errorTitle, setErrorTitle] = useState('');


  // const uiSchema = {
  //   'firewall_rules': firewallRulesUISchema,
  //   'ui:submitButtonOptions': {
  //     norender: { liveValidate },
  //     submitText: "Validate"
  //   },
  // };

  const [uiSchema, setUiSchema] = useState({
    'firewall_rules': firewallRulesUISchema,
    'ui:submitButtonOptions': {
      norender: liveValidate,
      submitText: "Validate"
    },
  });

  useEffect(() => {
    // Update the uiSchema whenever liveValidate changes 
    setUiSchema({
      'firewall_rules': firewallRulesUISchema,
      'ui:submitButtonOptions': {
        norender: liveValidate,
        submitText: "Validate"
      },
    });
  }, [liveValidate]); // This effect runs when `liveValidate` changes

  // Reset form data to initial state
  const resetFormData = () => {
    setFormData({});
  };

  // Copy JSON to clipboard
  const copyJsonToClipboard = (formData) => {
    const dataStr = JSON.stringify(formData.firewall_rules, null, 2);
    navigator.clipboard.writeText(dataStr).catch(err => {
      console.error('Could not copy text: ', err);
    });
  };

  // Generate and copy the shareable link
  const shareFormData = () => {
    const base64EncodedData = btoa(JSON.stringify(formData.firewall_rules));
    const currentUrl = window.location.href.split('?')[0];
    const shareableLink = `${currentUrl}?formData=${base64EncodedData}`;

    navigator.clipboard.writeText(shareableLink).catch(err => {
      console.error('Failed to copy shareable link: ', err);
    });
  };

  // Load JSON from modal
  const loadJsonFromModal = async () => {
    try {
      const formData = JSON.parse(modalInputData);
      setFormData({ firewall_rules: formData });
      toggleModal();
    } catch (err) {
      console.error('Failed to load JSON from clipboard:', err);
    }
  };

  // Toggle schema validation
  const toggleLiveValidator = () => {
    setLiveValidate(!liveValidate);
  };


  // Toggle schema validation
  const toggleSchemaValidation = () => {
    setValidateSchema(!validateSchema);
  };

  // Validate modal text area
  const validateModalTextArea = useCallback(() => {
    if (!validateSchema) {
      setIsInputValid(true);
      setErrorTitle('');
      return;
    }
    try {
      const inputData = JSON.parse(modalInputData);
      const valid = validate(inputData);
      setIsInputValid(valid);
      setErrorTitle(valid ? '' : formatErrors(validate.errors));
    } catch (err) {
      setIsInputValid(false);
      setErrorTitle(err.toString());
    }
  }, [validateSchema, modalInputData]);

  // Effect to validate the modal text area when `validateSchema` or `modalInputData` changes
  useEffect(() => {
    validateModalTextArea();
  }, [validateModalTextArea]);

  // Handle form data change
  const handleFormDataChange = ({ formData }) => {
    setFormData(formData);
  };

  // Parse Query Param and load state into form
  useEffect(() => {
    const parseAndCleanQueryParams = () => {
      const queryParams = new URLSearchParams(window.location.search);
      const formDataParam = queryParams.get('formData');
      if (formDataParam) {
        try {
          const decodedData = JSON.parse(atob(formDataParam));
          setFormData({ firewall_rules: decodedData });
          // Remove the query parameter from the URL
          const newUrl = window.location.pathname;
          window.history.replaceState({}, '', newUrl);
        } catch (error) {
          console.error('Error decoding formData from URL parameter:', error);
        }
      }
    };

    parseAndCleanQueryParams();
  }, []);

  // Handle modal input change
  const handleModalInputChange = (e) => {
    const input = e.target.value;
    setModalInputData(input);
    // Optionally, validate as user types or on input change
    // validateModalTextArea();
  };

  // Toggle modal visibility
  const toggleModal = () => {
    setShowModal(!showModal);
    if (!showModal) {
      // Pre-fill modal with current formData when opening
      setModalInputData(JSON.stringify(formData.firewall_rules, null, 2));
    }
  };

  return (
    <div className="App container mt-5 split-screen">
      <div className="top-pane">
        {/* <center style={{ paddingBottom: '15px' }}> */}
        {/* Button actions */}
        {/* Validation Toggle Button */}
        <button onClick={toggleLiveValidator} className={`btn btn-lg ${liveValidate ? 'btn-success' : 'btn-danger'}`} title="Toggle Validation">
          <FontAwesomeIcon icon={liveValidate ? faToggleOn : faToggleOff} /> Live Validation
        </button>
        <button onClick={shareFormData} className="btn btn-info btn-lg" title="Share FormData">
          <FontAwesomeIcon icon={faShareAlt} /> Share
        </button>
        <button onClick={() => copyJsonToClipboard(formData)} className="btn btn-info btn-lg" title="Copy to Clipboard">
          <FontAwesomeIcon icon={faCopy} /> Copy
        </button>
        <button onClick={toggleModal} className="btn btn-info btn-lg" title="View JSON">
          <FontAwesomeIcon icon={faEye} /> Edit / View
        </button>
        <button onClick={() => window.open(document.location.pathname + "./documentation", "_blank")} className="btn btn-info btn-lg" title="View Documentation">
          <FontAwesomeIcon icon={faBook} /> View Documentation
        </button>
        <button onClick={resetFormData} className="btn btn-danger btn-lg" title="Reset Form">
          Reset Form
        </button>
        {/* </center> */}
      </div>

      {/* Modal for editing/viewing JSON */}
      {showModal && (
        <div id="myModal" className="modal fade in" role="dialog" style={{ display: 'block' }}>
          <div className="modal-dialog">
            <div className="modal-content">
              <div className="modal-header">
                <button type="button" className="close" onClick={toggleModal}>&times;</button>
                <h4 className="modal-title">Form Data JSON</h4>
              </div>
              <div className="modal-body">
                <textarea className="editable-pre"
                  rows="25"
                  cols="50"
                  value={modalInputData}
                  onChange={handleModalInputChange}
                  style={{ whiteSpace: "pre-wrap" }}
                />
              </div>
              <div className="modal-footer">
                <div className="controls-container">
                  <label className="custom-control-label">Enable Schema Validation</label>
                  <div className="custom-control custom-switch">
                    <input
                      type="checkbox"
                      className="custom-control-input"
                      id="schemaValidationToggle"
                      onChange={toggleSchemaValidation}
                      checked={validateSchema}
                    />
                    <label className="slider-round" htmlFor="schemaValidationToggle"></label>
                  </div>
                  <button type="button"
                    title={!isInputValid ? errorTitle : ""}
                    disabled={!isInputValid}
                    className="btn btn-warning"
                    onClick={loadJsonFromModal}>Load JSON</button>
                  <button type="button" className="btn btn-secondary" onClick={() => copyJsonToClipboard(formData)}>Copy JSON</button>
                  <button type="button" className="btn btn-primary" onClick={toggleModal}>Close</button>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
      {showModal && <div className="modal-backdrop fade in"></div>}
      <div className="bottom-pane">
        <Form
          schema={schema}
          uiSchema={uiSchema}
          formData={formData}
          onChange={handleFormDataChange}
          liveValidate={liveValidate}
          validator={validator}
          templates={{
            DescriptionFieldTemplate,
          }}
        />
      </div>
    </div>
  );
}

export default App;
