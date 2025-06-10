import React, { useState } from 'react';
import { AlertCircle, Home, DollarSign, Loader2 } from 'lucide-react';

const HousingPricePredictor = () => {
  const [formData, setFormData] = useState({
    CRIM: 0.00632,     // per capita crime rate
    ZN: 18.0,          // proportion of residential land zoned for lots over 25,000 sq.ft.
    INDUS: 2.31,       // proportion of non-retail business acres
    CHAS: 0,           // Charles River dummy variable (1 if tract bounds river; 0 otherwise)
    NOX: 0.538,        // nitric oxides concentration (parts per 10 million)
    RM: 6.575,         // average number of rooms per dwelling
    AGE: 65.2,         // proportion of owner-occupied units built prior to 1940
    DIS: 4.0900,       // weighted distances to employment centres
    TAX: 296.0,        // full-value property-tax rate per $10,000
    PTRATIO: 15.3,     // pupil-teacher ratio by town
    LSTAT: 4.98       // % lower status of the population
  });
 
  const [prediction, setPrediction] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: parseFloat(value) || 0
    }));
  };

  const handleSubmit = async () => {
    setLoading(true);
    setError(null);
   
    try {
      const response = await fetch('/api/predict', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(formData)
      });
     
      if (!response.ok) {
        const errorText = await response.text();
        console.error('API Error:', response.status, errorText);
        throw new Error(`API Error: ${response.status} - ${errorText}`);
      }
     
      const contentType = response.headers.get('content-type');
      if (!contentType || !contentType.includes('application/json')) {
        const responseText = await response.text();
        console.error('Non-JSON response:', responseText);
        throw new Error('API returned non-JSON response');
      }
     
      const result = await response.json();
      setPrediction(result);
    } catch (err) {
      console.error('Full error:', err);
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 py-8">
      <div className="container mx-auto px-4 max-w-4xl">
        <div className="text-center mb-8">
          <div className="flex items-center justify-center mb-4">
            <Home className="w-12 h-12 text-indigo-600 mr-2" />
            <h1 className="text-4xl font-bold text-gray-900">Boston Housing Price Predictor</h1>
          </div>
          <p className="text-lg text-gray-600">Enter Boston area property details to get an estimated median home value</p>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
          {/* Form Section */}
          <div className="bg-white rounded-xl shadow-lg p-6">
            <h2 className="text-2xl font-semibold text-gray-800 mb-6">Property Details</h2>
           
            <div className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Crime Rate (CRIM)</label>
                  <input
                    type="number"
                    name="CRIM"
                    value={formData.CRIM}
                    onChange={handleInputChange}
                    min="0"
                    step="0.001"
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500"
                  />
                  <p className="text-xs text-gray-500">Per capita crime rate by town</p>
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Zoned Land (ZN)</label>
                  <input
                    type="number"
                    name="ZN"
                    value={formData.ZN}
                    onChange={handleInputChange}
                    min="0"
                    max="100"
                    step="0.1"
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500"
                  />
                  <p className="text-xs text-gray-500">% residential land zoned for lots over 25,000 sq.ft.</p>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Industry (INDUS)</label>
                  <input
                    type="number"
                    name="INDUS"
                    value={formData.INDUS}
                    onChange={handleInputChange}
                    min="0"
                    max="100"
                    step="0.01"
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500"
                  />
                  <p className="text-xs text-gray-500">% non-retail business acres per town</p>
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Charles River (CHAS)</label>
                  <select
                    name="CHAS"
                    value={formData.CHAS}
                    onChange={handleInputChange}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500"
                  >
                    <option value={0}>No</option>
                    <option value={1}>Yes</option>
                  </select>
                  <p className="text-xs text-gray-500">Bounds Charles River?</p>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">NOX Concentration</label>
                  <input
                    type="number"
                    name="NOX"
                    value={formData.NOX}
                    onChange={handleInputChange}
                    min="0"
                    max="1"
                    step="0.001"
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500"
                  />
                  <p className="text-xs text-gray-500">Nitric oxides concentration (parts per 10M)</p>
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Avg Rooms (RM)</label>
                  <input
                    type="number"
                    name="RM"
                    value={formData.RM}
                    onChange={handleInputChange}
                    min="1"
                    max="15"
                    step="0.001"
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500"
                  />
                  <p className="text-xs text-gray-500">Average number of rooms per dwelling</p>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Age (AGE)</label>
                  <input
                    type="number"
                    name="AGE"
                    value={formData.AGE}
                    onChange={handleInputChange}
                    min="0"
                    max="100"
                    step="0.1"
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500"
                  />
                  <p className="text-xs text-gray-500">% owner-occupied units built prior to 1940</p>
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Distance (DIS)</label>
                  <input
                    type="number"
                    name="DIS"
                    value={formData.DIS}
                    onChange={handleInputChange}
                    min="0"
                    step="0.0001"
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500"
                  />
                  <p className="text-xs text-gray-500">Weighted distances to employment centres</p>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Tax Rate (TAX)</label>
                  <input
                    type="number"
                    name="TAX"
                    value={formData.TAX}
                    onChange={handleInputChange}
                    min="0"
                    step="1"
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500"
                  />
                  <p className="text-xs text-gray-500">Property-tax rate per $10,000</p>
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Pupil-Teacher Ratio</label>
                  <input
                    type="number"
                    name="PTRATIO"
                    value={formData.PTRATIO}
                    onChange={handleInputChange}
                    min="1"
                    max="50"
                    step="0.1"
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500"
                  />
                  <p className="text-xs text-gray-500">Pupil-teacher ratio by town</p>
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Lower Status % (LSTAT)</label>
                <input
                  type="number"
                  name="LSTAT"
                  value={formData.LSTAT}
                  onChange={handleInputChange}
                  min="0"
                  max="100"
                  step="0.01"
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500"
                />
                <p className="text-xs text-gray-500">% lower status of the population</p>
              </div>

              <button
                onClick={handleSubmit}
                disabled={loading}
                className="w-full bg-indigo-600 text-white py-3 px-4 rounded-md hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 disabled:opacity-50 flex items-center justify-center"
              >
                {loading ? (
                  <>
                    <Loader2 className="w-4 h-4 mr-2 animate-spin" />
                    Predicting...
                  </>
                ) : (
                  <>
                    <DollarSign className="w-4 h-4 mr-2" />
                    Get Price Prediction
                  </>
                )}
              </button>
            </div>
          </div>

          {/* Results Section */}
          <div className="bg-white rounded-xl shadow-lg p-6">
            <h2 className="text-2xl font-semibold text-gray-800 mb-6">Prediction Results</h2>
           
            {error && (
              <div className="bg-red-50 border border-red-200 rounded-md p-4 mb-4">
                <div className="flex items-center">
                  <AlertCircle className="w-5 h-5 text-red-400 mr-2" />
                  <p className="text-red-700">{error}</p>
                </div>
              </div>
            )}

            {prediction && (
              <div className="space-y-4">
                <div className="bg-green-50 border border-green-200 rounded-md p-6 text-center">
                  <h3 className="text-lg font-medium text-green-800 mb-2">Estimated Median Home Value</h3>
                  <p className="text-3xl font-bold text-green-600">${prediction.predicted_price?.toFixed(2) || 'N/A'}K</p>
                </div>
               
                <div className="bg-gray-50 rounded-md p-4">
                  <h4 className="font-medium text-gray-800 mb-2">Area Summary</h4>
                  <div className="grid grid-cols-2 gap-2 text-sm text-gray-600">
                    <div>Crime Rate: {formData.CRIM}</div>
                    <div>Avg Rooms: {formData.RM}</div>
                    <div>Age: {formData.AGE}%</div>
                    <div>Tax Rate: ${formData.TAX}</div>
                    <div>PT Ratio: {formData.PTRATIO}</div>
                    <div>Lower Status: {formData.LSTAT}%</div>
                  </div>
                </div>
              </div>
            )}

            {!prediction && !error && (
              <div className="text-center text-gray-500 py-8">
                <Home className="w-16 h-16 mx-auto mb-4 text-gray-300" />
                <p>Enter Boston area details and click "Get Price Prediction" to see the estimated median home value.</p>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default HousingPricePredictor;