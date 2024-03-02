// import React from 'react';
import { withTheme, default as Form } from '@rjsf/core';


import { Theme as Bootstrap3Theme } from '@rjsf/core';

import { ArrayFieldTemplateProps, DescriptionFieldProps, RJSFSchema } from '@rjsf/utils';

import firewallRulesRawSchema from './schemas/resolved.schema.json';
import firewallRulesUISchema from './schemas/UISchema.json';
import Ajv from 'ajv';
// import ajvErrors from 'ajv-errors';

import validator from '@rjsf/validator-ajv8';
// import './App.css'; // Assuming your custom CSS is here
import './modal.css';

import React, { useState } from 'react';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { faCopy, faPaste, faEye, faBook } from '@fortawesome/free-solid-svg-icons';
// import CustomFieldTemplate from './CustomFieldTemplate.tsx';
import Modal from 'react-bootstrap/Modal';
import Button from 'react-bootstrap/Button';
// import { toErrorList } from '@rjsf/core/lib/validate';
// import { Tooltip, OverlayTrigger } from 'react-bootstrap';

import 'bootstrap/dist/css/bootstrap.min.css';

import Tooltip from '@mui/material/Tooltip';
import IconButton from '@mui/material/IconButton';
import HelpOutlineIcon from '@mui/icons-material/HelpOutline';

// import { customArray } from './customArray.js';

// import { ArrayFieldTemplateProps } from '@rjsf/utils';

// // Initialize AJV with options suitable for your needs
const ajv = new Ajv({ strict: false, allErrors: true, useDefaults: true });
// ajvErrors(ajv); // Optional: Use ajv-errors for better error messages
const validate = ajv.compile(firewallRulesRawSchema)
const schema = {
  type: "object",
  properties: {
    firewall_rules: firewallRulesRawSchema
  }
}

function CustomFieldTemplate(props) {
  const { id, classNames, label, help, required, description, errors, children } = props;
  return (
    <div className={classNames}>
      winner
      <label htmlFor={id}>{label}{required ? "A" : null}</label>
      {description}
      {children}
      {errors}
      {help}
    </div>
  );
}


const uiSchema = {
  'firewall_rules': firewallRulesUISchema,
  'ui:submitButtonOptions': {
    norender: true
  },
  // 'firewall_rules': {
  //   // 'ui:ArrayFieldTemplate': CustomFieldTemplate,
  //   items: {
  //     direction: {
  //       // 'ui:FieldTemplate': CustomFieldTemplate,
  //     }
  //   }
  //   //   // 'ui:ArrayFieldItemTemplate': ArrayFieldItemTemplate,
  //   //   "ui:options": {
  //   //     "copyable": true
  //   //   },
  //   //   'items': {
  //   //     'direction': {
  //   //       'ui:DescriptionFieldTemplate': DescriptionFieldTemplate
  //   //     }
  //   //   }
  // }
}

function ArrayFieldTemplate(props) {
  const { children, className, onAddClick, canAdd } = props;
  return (
    <div>
      {props.items.map((element) => element.children)}
      {props.canAdd && <button type='button' onClick={props.onAddClick}
        // class='btn btn-info btn-add col-xs-12' 
        className={className}
        title='Add'>Add </button>}
      {props.hasRemove && <button type='button' onClick={props.onAddClick}
        // class='btn btn-info btn-add col-xs-12' 
        className={className}
        title='Add'>Remove </button>}
      {/* {props.canDe && <button type='button' onClick={props.onAddClick}></button>} */}
    </div>
  );
}

function ArrayFieldItemTemplate(props) {
  const { children, className } = props;
  return (
    <>
      <div className={className} >{children}</div>
      <div class="col-xs-3 array-item-toolbox">
        <div class="btn-group" style="display: flex; justify-content: space-around;">
          <button type="button" class="btn btn-default array-item-copy" title="Copy" style="flex: 1 1 0%; padding-left: 6px; padding-right: 6px; font-weight: bold;">
            <i class="glyphicon glyphicon-copy"></i>
          </button><button type="button" class="btn btn-danger array-item-remove" title="Remove" style="flex: 1 1 0%; padding-left: 6px; padding-right: 6px; font-weight: bold;">
            <i class='glyphicon glyphicon-remove'></i>
          </button>
        </div>
      </div>
    </>
  );
}

function DescriptionFieldTemplate(props) {
  const { description, id } = props;
  return (
    <Tooltip title={description} >
      <IconButton size="small">
        <HelpOutlineIcon />
      </IconButton>
    </Tooltip>
  );
}

function formatErrors(errors) {
  return errors
    .filter(error => error.keyword !== 'const' && error.keyword !== 'x') // Exclude errors with 'const' or 'x'
    .map(error => `${error.instancePath}, ${error.schemaPath}, ${error.message}`)
    .join('\n'); // Join errors with newline for title attribute usage
}


// Define a function to handle form submission
const onSubmit = ({ formData }, e) => console.log("Data submitted: ", formData);

function App() {
  const [formData, setFormData] = useState({}); // Initial form data
  const [showModal, setShowModal] = useState(false);
  const [isInputValid, setIsInputValid] = useState(true);
  const [modalInputData, setModalInputData] = useState("");
  const [errorTitle, setErrorTitle] = useState('');

  const resetFormData = () => {
    setFormData({}); // Reset form data to initial state, adjust { } as needed
    console.log('Form data has been reset');
  };

  const copyJsonToClipboard = (formData) => {
    const dataStr = JSON.stringify(formData.firewall_rules, null, 2);
    navigator.clipboard.writeText(dataStr).then(() => {
      console.log('FormData copied to clipboard');
    }, (err) => {
      console.error('Could not copy text: ', err);
    });
  };

  const loadJsonFromClipboard = async () => {
    try {
      // const text = await navigator.clipboard.readText(); // Read text from clipboard
      // const formData = JSON.parse(text); // Attempt to parse it as JSON
      const formData = JSON.parse(modalInputData)
      setFormData({ firewall_rules: formData }); // Update your form's state
      console.log('FormData loaded from clipboard');
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
    // console.log("Button")
    try {
      const inputData = JSON.parse(e.target.value);
      const valid = validate(inputData);
      setIsInputValid(valid)
      if (!valid) {
        console.log(validate.errors);
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
    // console.log("Toggle clicked")
    console.log("Toggling modal from", showModal, "to", !showModal);
    setShowModal(!showModal)
    if (!showModal) {
      setModalInputData(JSON.stringify(formData.firewall_rules, null, 2));
    }
  };

  return (
    <div className="App container mt-5">

      <center>
        {/* <button onClick={() => loadJsonFromClipboard(formData)} className="btn btn-info btn-lg" title="Paste from Clipboard">
          <FontAwesomeIcon icon={faPaste} /> Load FormData
        </button> */}
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
                // onChange={(e) => console.log(e.target.value)}
                />
              </div>
              <div className="modal-footer">
                <button type="button"
                  title={!isInputValid ? errorTitle : ""}
                  disabled={!isInputValid}
                  className="btn btn-warning"
                  onClick={() => loadJsonFromClipboard(modalInputData)}>Load JSON</button>
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
        onSubmit={onSubmit}
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
