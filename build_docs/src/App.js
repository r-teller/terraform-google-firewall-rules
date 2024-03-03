
import { default as Form } from '@rjsf/core';

import firewallRulesRawSchema from './schemas/JSONSchema.json';
import firewallRulesUISchema from './schemas/UISchema.json';
import Ajv from 'ajv';

import validator from '@rjsf/validator-ajv8';
import './modal.css';
import './firewall-rules.css'

import React, { useState } from 'react';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { faCopy, faEye, faBook } from '@fortawesome/free-solid-svg-icons';


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
  // const { description, id } = props;
  // return (
  //   <Tooltip title={description} >
  //     <IconButton size="small">
  //       <HelpOutlineIcon />
  //     </IconButton>
  //   </Tooltip>
  // );
}

function formatErrors(errors) {
  return errors
    .filter(error => error.keyword !== 'const' && error.keyword !== 'x') // Exclude errors with 'const' or 'x'
    .map(error => `${error.instancePath}, ${error.schemaPath}, ${error.message}`)
    .join('\n'); // Join errors with newline for title attribute usage
}


// Define a function to handle form submission
// const onSubmit = ({ formData }, e) => console.log("Data submitted: ", formData);

function App() {
  const [formData, setFormData] = useState({}); // Initial form data
  const [showModal, setShowModal] = useState(false);
  const [isInputValid, setIsInputValid] = useState(true);
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

  const loadJsonFromModal = async () => {
    try {
      const formData = JSON.parse(modalInputData)
      setFormData({ firewall_rules: formData }); // Update your form's state
      toggleModal();
    } catch (err) {
      console.error('Failed to load JSON from clipboard:', err);
    }
  };

  // Used to track state for main form
  const handleFormDataChange = ({ formData }) => {
    setFormData(formData);
  };

  const handleModalInputChange = (e) => {
    try {
      const inputData = JSON.parse(e.target.value);
      const valid = validate(inputData);
      setIsInputValid(valid)
      if (!valid) {
        setErrorTitle(formatErrors(validate.errors));
      }

    } catch (err) {
      setIsInputValid(false)
      setErrorTitle(err)
      console.error('Failed to load JSON from input:', err);
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

      <center>

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
