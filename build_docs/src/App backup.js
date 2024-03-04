
import { default as Form } from '@rjsf/core';

import firewallRulesRawSchema from './schemas/JSONSchema.json';
import firewallRulesUISchema from './schemas/UISchema.json';
import Ajv from 'ajv';

import validator from '@rjsf/validator-ajv8';
import './modal.css';
import './firewall-rules.css'

import React, { useState, useEffect, useCallback } from 'react';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { faCopy, faEye, faBook, faShareAlt } from '@fortawesome/free-solid-svg-icons';


import 'bootstrap/dist/css/bootstrap.min.css';

// // Initialize AJV with options suitable for your needs
const ajv = new Ajv({ strict: false, allErrors: true, useDefaults: true });

const validate = ajv.compile(firewallRulesRawSchema)
const schema = {
  type: "object",
  properties: {
    firewall_rules: firewallRulesRawSchema
  }
}

const uiSchema = {
  'firewall_rules': firewallRulesUISchema,
  'ui:submitButtonOptions': {
    norender: true
  },
}

function DescriptionFieldTemplate(props) {
  return null;
}

function formatErrors(errors) {
  return errors
    .filter(error => error.keyword !== 'const' && error.keyword !== 'x') // Exclude errors with 'const' or 'x'
    .map(error => `${error.instancePath}, ${error.schemaPath}, ${error.message}`)
    .join('\n'); // Join errors with newline for title attribute usage
}

function App() {
  const [formData, setFormData] = useState({}); // Initial form data
  const [showModal, setShowModal] = useState(false);
  const [isInputValid, setIsInputValid] = useState(true);
  const [validateSchema, setValidateSchema] = useState(true); // New state for toggling schema validation
  const [modalInputData, setModalInputData] = useState("");
  const [errorTitle, setErrorTitle] = useState('');

  const resetFormData = () => {
    setFormData({}); // Reset form data to initial state, adjust { } as needed
  };

  const copyJsonToClipboard = (formData) => {
    const dataStr = JSON.stringify(formData.firewall_rules, null, 2);
    navigator.clipboard.writeText(dataStr).then(() => { }, (err) => {
      console.error('Could not copy text: ', err);
    });
  };

  // Function to generate and copy the shareable link
  const shareFormData = () => {
    const base64EncodedData = btoa(JSON.stringify(formData.firewall_rules));
    const currentUrl = window.location.href.split('?')[0]; // Remove existing query parameters if any
    const shareableLink = `${currentUrl}?formData=${base64EncodedData}`;

    navigator.clipboard.writeText(shareableLink).then(() => { }, (err) => {
      console.error('Failed to copy shareable link: ', err);
    });
  };

  const loadJsonFromModal = async () => {
    try {
      const formData = JSON.parse(modalInputData)
      setFormData({ firewall_rules: formData }); // Update your form's state
      toggleModal();
    } catch (err) {
      console.error('Failed to load JSON from clipboard:', err);
    }
  };

  const toggleSchemaValidation = () => {
    setValidateSchema(!validateSchema);
    validateModalTextArea()
  };

  const validateModalTextArea = useCallback(() => {
    try {
      console.log("Schema => " + validateSchema)
      const inputData = JSON.parse(modalInputData);
      const valid = validate(inputData);
      if (validateSchema) {
        setIsInputValid(valid);
        if (!valid) {
          setErrorTitle(formatErrors(validate.errors));
        } else {
          setErrorTitle(''); // Clear error title if valid
        }
      } else {
        setIsInputValid(true); // If validation is turned off, always set to valid
        setErrorTitle(''); // Clear any existing error messages
      }
    } catch (err) {
      setIsInputValid(false);
      setErrorTitle(err.toString()); // Display the error message
    }
  }, [validateSchema, modalInputData, validate, formatErrors]); // Include all dependencies here

  useEffect(() => {
    validateModalTextArea();
  }, [validateModalTextArea]); // Now validateModalTextArea is a dependency, but it's memoized with useCallback

  // const validateModalTextArea = () => {
  //   try {
  //     console.log("Schema => " + modalInputData)
  //     const inputData = JSON.parse(modalInputData);
  //     const valid = validate(inputData);
  //     console.log("Validation => " + validateSchema)
  //     if (validateSchema) {
  //       setIsInputValid(valid)
  //     } else {
  //       setIsInputValid(true)
  //     }

  //     if (!valid) {
  //       setErrorTitle(formatErrors(validate.errors));
  //     }

  //   } catch (err) {
  //     setIsInputValid(false)
  //     setErrorTitle(err)

  //   }
  // }

  // useEffect(() => {
  //   validateModalTextArea(); // Call the validation function when the schema validation state changes
  // }, [validateSchema, modalInputData]);

  // Used to track state for main form
  const handleFormDataChange = ({ formData }) => {
    setFormData(formData);
  };

  useEffect(() => {
    // Function to parse query parameters and remove them
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



  const handleModalInputChange = (e) => {
    try {
      const inputData = JSON.parse(e.target.value);
      const valid = validate(inputData);
      console.log("Schema => " + valid)
      console.log("Validation => " + validateSchema)
      if (validateSchema) {
        setIsInputValid(valid)
      } else {
        setIsInputValid(true)
      }

      if (!valid) {
        setErrorTitle(formatErrors(validate.errors));
      }

    } catch (err) {
      setIsInputValid(false)
      setErrorTitle(err)

    }
    // // Update modal input data without affecting formData
    setModalInputData(e.target.value);
  };

  const toggleModal = () => {
    setShowModal(!showModal)
    if (!showModal) {
      setModalInputData(JSON.stringify(formData.firewall_rules, null, 2));
    }
  };

  return (
    <div className="App container mt-5">

      <center style={{ paddingBottom: '15px' }}>
        <button onClick={shareFormData} className="btn btn-info btn-lg" title="Share FormData">
          <FontAwesomeIcon icon={faShareAlt} /> Share FormData
        </button>
        <button onClick={() => copyJsonToClipboard(formData)} className="btn btn-info btn-lg" title="Copy to Clipboard">
          <FontAwesomeIcon icon={faCopy} /> Copy FormData
        </button>
        <button onClick={toggleModal} className="btn btn-info btn-lg" title="View JSON">
          <FontAwesomeIcon icon={faEye} /> Edit / View FormData
        </button>
        <button onClick={() => window.open(document.location.pathname + "./documentation", "_blank")} className="btn btn-info btn-lg" title="View Documentation">
          <FontAwesomeIcon icon={faBook} /> View Documentation
        </button>
        <button onClick={resetFormData} className="btn btn-danger btn-lg" title="Reset Form">
          Reset Form
        </button>
      </center>


      {/* Modal */}
      {showModal && (
        <div id="myModal" className="modal fade in" role="dialog" style={{ display: 'block' }}>
          <div className="modal-dialog">
            {/* Modal content*/}
            <div className="modal-content">
              <div className="modal-header">
                <button type="button" className="close" onClick={toggleModal}>&times;</button>
                <h4 className="modal-title">Form Data JSON</h4>
              </div>
              <div className="modal-body">
                <textarea className="editable-pre"
                  rows="25" // Adjust the number of rows as needed
                  cols="50" // Adjust the number of columns as needed
                  value={modalInputData}
                  onChange={handleModalInputChange}
                  style={{ whiteSpace: "pre-wrap" }}
                />
              </div>
              <div className="modal-footer">
                <div className="controls-container">

                  <label class="custom-control-label">Enable Schema Validation</label>
                  <div class="custom-control custom-switch">
                    <input
                      type="checkbox"
                      class="custom-control-input"
                      id="schemaValidationToggle"
                      // onClick={validateSchema}
                      // onClick={console.log("RedPanda was here v2")}
                      onChange={toggleSchemaValidation}
                      // checked
                      checked={validateSchema} // This line ensures the checkbox reflects the state
                    // onChange={() => console.log("Checkbox state changed")}
                    />
                    <label class="slider-round" for="schemaValidationToggle"></label>

                  </div>


                  <button type="button"
                    title={!isInputValid ? errorTitle : ""}
                    disabled={!isInputValid}
                    className="btn btn-warning"
                    onClick={() => loadJsonFromModal(modalInputData)}>Load JSON</button>
                  <button type="button" className="btn btn-secondary" onClick={() => copyJsonToClipboard(formData)}>Copy JSON</button>
                  <button type="button" className="btn btn-primary" onClick={toggleModal}>Close</button>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
      {showModal && <div className="modal-backdrop fade in"></div>}


      {/* "ui:ArrayFieldTemplate": "ArrayFieldTemplate", */}
      {/* "ui:DescriptionFieldTemplate": "DescriptionFieldTemplate", */}
      <Form
        schema={schema}
        uiSchema={uiSchema}
        // onSubmit={onSubmit}
        formData={formData}
        onChange={handleFormDataChange}
        liveValidate
        validator={validator}

        templates={{
          DescriptionFieldTemplate,
          // CustomFieldTemplate,
        }}
      // FieldTemplate={{ CustomFieldTemplate }}
      // fields={{ ArrayFieldTemplate }}
      />
    </div>
  );
}

export default App;
